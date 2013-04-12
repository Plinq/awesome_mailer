require 'abstract_controller'
require 'action_mailer'

module AwesomeMailer
  class Base < ActionMailer::Base
    abstract!
    include ActionView::Helpers::AssetTagHelper::StylesheetTagHelpers
    include ActionView::Helpers::AssetTagHelper::JavascriptTagHelpers
    include AbstractController::UrlFor

    def render(*arguments)
      return super unless formats.include? :html
      AwesomeMailer::Renderer.new(super).to_html
    end
  end
end
