require 'rubygems'
require 'action_mailer'
require 'hpricot'
require 'css_parser'

module AwesomeMailer
  class Base < ActionMailer::Base
    abstract!

    def render(*arguments)
      html_string = super
      document = Hpricot(html_string)
      stylesheets = document.search('link[@rel=stylesheet]')
      stylesheets.each do |stylesheet|
        if stylesheet['media'] =~ /^(all|handheld|screen)$/ # Must be intended for digital screens!
          apply_stylesheet!(document, stylesheet)
        end
      end
      stylesheets.remove
      document.to_html
    end

    private
    def append_styles!(document, selector, declarations)
      unless head = document.at('head')
        head = Hpricot::Elem.new('head')
        document.children.unshift(head)
      end
      unless style = head.at('style[@type=text/css]')
        style = Hpricot::Elem.new('style')
        style['type'] = 'text/css'
        style.inner_html = "\n"
        head.children.unshift(style)
      end
      style.inner_html += "#{selector} { #{declarations} }\n"
    end

    def apply_rules!(document, css_parser, url)
      css_parser.each_selector do |selector, declarations, specificity|
        if url
          # Rewrite relative URLs to match their parent CSS's URL path
          path_url = Addressable::URI.parse(url)
          path_url.path = File.dirname(path_url.path)
          declarations.scan(/(url\(?["']+(.[^'"]*)["']\))/i).each do |url_command, item|
            next if item =~ /^http(s){0,1}:\/\//
            item_url = path_url.dup
            item_url.path = File.join(item_url.path, item)
            new_url_command = url_command.gsub(item, item_url.to_s)
            declarations[url_command] = new_url_command
          end
        else
          declarations.reject {|item| item.match(/url\s*\(/) }
        end
        if selector =~ /(^@)/
          append_styles!(document, selector, declarations.to_s) if url
        elsif selector !~ /:/
          document.search(selector).each do |element|
            element['style'] = [element['style'], *declarations].compact.join(';')
          end
        end
      end
    end

    def apply_stylesheet!(document, stylesheet)
      css_parser = CssParser::Parser.new
      clean_href = stylesheet['href'].split('?').shift
      url = nil
      case stylesheet['href']
      when /^\/assets/
        dirname = File.dirname(clean_href).split('/').reject(&:blank?)[1..-1]
        css_parser.load_file!(File.join(Rails.root, 'app', 'assets', 'stylesheets', dirname, File.basename(clean_href)))
      when /^\//
        css_parser.load_file!(File.join(Rails.root, 'public', clean_href))
      else
        css_parser.load_uri!(stylesheet['href'])
        url = clean_href
      end      
      apply_rules!(document, css_parser, url)
    end
  end
end
