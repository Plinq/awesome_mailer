require 'abstract_controller'
require 'action_mailer'
require 'nokogiri'
require 'css_parser'

module AwesomeMailer
  class Base < ActionMailer::Base
    abstract!
    include ActionView::Helpers::AssetTagHelper::StylesheetTagHelpers
    include ActionView::Helpers::AssetTagHelper::JavascriptTagHelpers
    include AbstractController::UrlFor

    def render(*arguments)
      return super unless formats.include? :html
      document = Nokogiri::HTML(super)
      stylesheets = document.search('link[@rel=stylesheet]')
      stylesheets.each do |stylesheet|
        # Must be intended for digital screens!
        load_stylesheet(stylesheet) if stylesheet['media'] =~ /^(all|handheld|screen)$/
      end
      apply_css!(document)
      document.to_html
    end

    private
    def append_styles!(document, selector, declarations)
      header_stylesheet.inner_html += "#{selector} { #{declarations} }\n"
    end

    def apply_css!(document)
      css_parser.each_selector do |selector, declarations, specificity|
        # Rewrite relative URLs to match their parent CSS's URL path
        rewrite_relative_urls(declarations) if css_host
        if selector =~ /(^@|:)/
          # Include difficult styles in the head
          append_styles!(document, selector, declarations.to_s)
        else
          # Include regular styles inline
          document.search(selector).each do |element|
            element['style'] = [element['style'], *declarations].compact.join(';')
          end
        end
      end
    end

    def asset_pipeline_path
      return false unless sprockets?
      /^#{Regexp.escape(Rails.configuration.assets[:path])}\//
    end

    def css_host
      if host = self.class.default_url_options[:host]
        Addressable::URI.heuristic_parse(host, scheme: 'http')
      end
    end

    def css_parser
      @css_parser ||= CssParser::Parser.new
    end

    def document_head
      @document_head ||= document.at('head') || Hpricot::Elem.new('head').tap do |head|
        document.children.unshift(head)
      end
    end

    def header_stylesheet
      @header_stylesheet ||= document_head.at('style[@type=text/css]') || Hpricot::Elem.new('style').tap do |style|
        style['type'] = 'text/css'
        style.inner_html = "\n"
        head.children.unshift(style)
      end
    end

    def load_stylesheet(stylesheet)
      stylesheet_path = stylesheet['href'].split('?').shift
      stylesheet_path.gsub!(/^#{Regexp.escape(css_host)}/, '') if css_host
      case stylesheet_path
      when asset_pipeline_path
        if asset = read_asset_pipeline_asset(stylesheet_path)
          css_parser.add_block!(asset.to_s, :media_types => :all)
        end
      when /^\//
        local_path = rails? && Rails.root.join('public', stylesheet_path.gsub(/^\//, '')).to_s
        css_parser.load_file!(local_path) if local_path && File.file?(local_path)
      else
        css_parser.load_uri!(stylesheet['href'])
      end
      stylesheet.remove
    end

    def rails?
      defined? Rails
    end

    def read_asset_pipeline_asset(path)
      path = path.gsub(asset_pipeline_path, '')
      Rails.application.assets[path]
    end

    def rewrite_relative_urls(css_declarations)
      css_declarations.scan(/(url\s*\(?["']+(.[^'"]*)["']\))/i).each do |url_command, item|
        next if item =~ /^http(s){0,1}:\/\//
        item_url = css_host.dup
        item_url.path = File.join(item_url.path, item)
        new_url_command = url_command.gsub(item, item_url.to_s)
        css_declarations[url_command] = new_url_command
      end
    end

    def sprockets?
      rails? && Rails.application.respond_to?(:assets)
    end
  end
end
