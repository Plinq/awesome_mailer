require 'simplecov'
SimpleCov.start
require 'ostruct'
require 'awesome_mailer'
require 'pry'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Rails = OpenStruct.new(root: Pathname.new(File.dirname(__FILE__)))

AwesomeMailer::Base.prepend_view_path 'spec/views'
AwesomeMailer::Base.config.assets_dir = 'spec/assets'

class TestMailer < AwesomeMailer::Base
  def render_template(template_name)
    mail(from: "flip@x451.com", to: "flip@x451.com", subject: "Test e-mail") do |format|
      format.html { render template_name }
    end
  end

  def render_multipart_template(template_name)
     mail(from: "flip@x451.com", to: "flip@x451.com", subject: "Test multipart e-mail") do |format|
      format.html { render template_name }
      format.text { render template_name }
    end
  end
end

module AwesomeMailerTestHelper
  class AwesomeStruct < OpenStruct
    def [](key)
      send(key)
    end

    def []=(key, value)
      send("#{key}=", value)
    end
  end

  def load_asset_pipeline
    asset_pipeline = AwesomeStruct.new(
      "test.css" => File.read(File.join('spec', 'assets', 'stylesheets', 'test.css'))
    )
    assets = AwesomeStruct.new(prefix: '/stylesheets')
    action_mailer = AwesomeStruct.new(asset_host: nil)
    action_controller = AwesomeStruct.new(asset_host: nil)
    Rails.stub(:application) { AwesomeStruct.new(assets: asset_pipeline) }
    Rails.stub(:configuration) do
      AwesomeStruct.new(assets: assets, action_mailer: action_mailer, action_controller: action_controller)
    end
  end

  def wrap_in_html(string, head = "")
    html = [%{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">}]
    body = "<body>#{string}</body>"
    if head
      html.push "<html>"
      html.push "<head>#{head}</head>"
      html.push body
      html.push "</html>"
    else
      html.push "<html>#{body}</html>"
    end
    html.push ""
    html.join("\n")
  end
end

RSpec.configure do |config|
  config.include AwesomeMailerTestHelper
end
