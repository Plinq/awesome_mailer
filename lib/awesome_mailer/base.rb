require 'abstract_controller'
require 'action_mailer'

module AwesomeMailer
  class Base < ActionMailer::Base

    def render(*arguments)
      return super unless formats.include? :html
      AwesomeMailer::Renderer.new(super).to_html
    end

  end
end
