require 'action_dispatch'
require 'action_mailer'

module AwesomeMailer
  class Base < ActionMailer::Base
    abstract!
    include ActionView::Helpers::AssetTagHelper
    include ActionDispatch::Routing::UrlFor

    def render(*arguments)
      return super unless formats.include? :html
      AwesomeMailer::Renderer.new(super).to_html
    end
  end
end
