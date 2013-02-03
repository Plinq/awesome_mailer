require 'simplecov'
SimpleCov.start
require 'ostruct'
require 'awesome_mailer'

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
  def load_asset_pipeline
    asset_pipeline = {"test.css" => File.read(File.join('spec', 'assets', 'stylesheets', 'test.css'))}
    assets = {path: '/stylesheets'}
    Rails.stub(:application) { OpenStruct.new(assets: asset_pipeline) }
    Rails.stub(:configuration) { OpenStruct.new(assets: assets) }
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
