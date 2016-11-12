require 'css_parser'
require 'nokogiri'

module AwesomeMailer
  class Renderer
    attr_accessor :document

    def initialize(document_string)
      self.document = Nokogiri::HTML.parse(document_string)
      stylesheets = document.search('link[@rel=stylesheet]')
      stylesheets.each do |stylesheet|
        # Must be intended for digital screens!
        load_stylesheet(stylesheet) if stylesheet['media'] =~ /^(all|handheld|screen)$/
      end
      inline_stylesheets = document.search('style')
      inline_stylesheets.each do |styles|
        css_parser.add_block!(styles.inner_html)
        styles.remove
      end
      apply_css!
    end

    def to_html
      document.to_html
    end

    private
    def apply_styles_to_body!(selector, properties)
      search_selector = selector =~ /^body/ ? selector : "body #{selector}"
      elements = document.search(search_selector)
      rewrite_relative_urls(properties) if host
      elements.each do |element|
        element['style'] = [element['style'], properties].flatten.compact.join('; ')
      end
    rescue Nokogiri::CSS::SyntaxError # Complex CSS? Just dump it somewhere
      apply_styles_to_head!(selector, properties)
    rescue RuntimeError => exception
      raise $! unless exception.message =~ /xmlXPathCompOpEval/
      apply_styles_to_head!(selector, properties)
    end

    def apply_styles_to_head!(selector, properties, indent = 0)
      rewrite_relative_urls(properties) if host
      header_stylesheet.content += "#{" " * indent}#{selector} { #{properties.join('; ')} }\n"
    end

    def apply_css!
      css_parser.compact!
      applied_rules = []

      # Apply @media queries to the document head
      css_parser.rules_by_media_query.each do |media_query, rules|
        next if media_query == :all
        header_stylesheet.content += "@media #{media_query} {\n"
        rules.each do |rule|
          rule.each_selector do |selector, properties, specificity|
            properties = properties.split(';').map(&:strip)
            apply_styles_to_head!(selector, properties, 2)
          end
        end
        header_stylesheet.content += "}\n"
        applied_rules.push(*rules)
      end

      # Apply all other styles
      css_parser.each_rule_set do |rule|
        next if applied_rules.include? rule
        rule.each_selector do |selector, properties, specificity|
          properties = properties.split(';').map(&:strip)
          if selector =~ /(^@|:(active|checked|disabled|enabled|focus|hover|lang|link|target|visited|not|:)|moz|webkit)/
            # Special selectors get sent to the <head> tag
            apply_styles_to_head!(selector, properties)
          else
            vendor_specific_properties = properties.select {|property| property =~ /^-/ }
            # Special properties get sent to the <head> tag
            apply_styles_to_head!(selector, vendor_specific_properties) unless vendor_specific_properties.empty?
            # Everything else winds up inline on the body
            apply_styles_to_body!(selector, properties - vendor_specific_properties)
          end
        end
      end
    end

    def asset_host
      rails? && (
        Rails.configuration.action_mailer.try(:asset_host) ||
        Rails.configuration.action_controller.try(:asset_host)
      )
    end

    def asset_pipeline_path
      return false unless sprockets?
      path = File.join('', Rails.configuration.assets[:prefix], '').gsub('//', '/')
      /^#{Regexp.escape(path)}/
    end

    def css_parser
      @css_parser ||= CssParser::Parser.new(absolute_paths: true)
    end

    def default_host
      if host = AwesomeMailer::Base.default_url_options[:host]
        "#{AwesomeMailer::Base.default_url_options[:scheme] || 'http'}://#{host}"
      end
    end

    def head
      @head ||= document.at('head') || Nokogiri::XML::Node.new('head', document.root).tap do |head|
        document.root.children.first.add_previous_sibling(head)
      end
    end

    def header_stylesheet
      @header_stylesheet ||= head.at('style[@type="text/css"]') || Nokogiri::XML::Node.new('style', head).tap do |style|
        style['type'] = 'text/css'
        style.content = "\n"
        head.add_child(style)
      end
    end

    def host
      if host = asset_host || default_host
        Addressable::URI.heuristic_parse(host, scheme: 'http')
      end
    end

    def load_stylesheet(stylesheet)
      stylesheet_path = stylesheet['href'].split('?').shift
      stylesheet_path.gsub!(/^#{Regexp.escape(host)}/, '') if host
      case stylesheet_path
      when asset_pipeline_path
        if asset = read_asset_pipeline_asset(stylesheet_path)
          css_parser.add_block!(asset.to_s)
        else
          Rails.logger.error 'AwesomeMailer error. Could not find: ' + stylesheet_path if rails?
        end
      when /^\//
        local_path = rails? && Rails.root.join('public', stylesheet_path.gsub(/^\//, '')).to_s
        css_parser.load_file!(local_path, nil, []) if local_path && File.file?(local_path)
      else
        dirname = File.dirname(stylesheet['href'])
        css_parser.load_uri!(stylesheet['href'], base_uri: dirname, media_types: [])
      end
      stylesheet.remove
    end

    def rails?
      defined? Rails
    end

    def read_asset_pipeline_asset(path)
      path = path.gsub(asset_pipeline_path, '').gsub(/-[A-Fa-f0-9]{64}/, '')
      if Rails.application.assets.nil?
        Rails.application.assets_manifest.assets[path]
      else
        Rails.application.assets[path]
      end
    end

    def rewrite_relative_urls(properties)
      properties.each do |property|
        property.scan(/(url\s*\(?["']+(.[^'"]*)["']\))/i).each do |url_command, item|
          next if item =~ /^http(s){0,1}:\/\//
          item_url = host.dup
          item_url.path = File.join(item_url.path, item)
          new_url_command = url_command.gsub(item, item_url.to_s)
          property[url_command] = new_url_command
        end
      end
    end

    def sprockets?
      rails? && Rails.application.respond_to?(:assets)
    end
  end
end
