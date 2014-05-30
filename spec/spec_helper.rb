#require 'simplecov'
#SimpleCov.start
require 'ostruct'
require 'awesome_mailer'
require 'pry'
require 'capybara'

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

  def file_root
    File.expand_path('public', File.dirname(__FILE__))
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

  def load_file_server
    server = Rack::Server.new(app: Rack::Directory.new(file_root), Port: "9876")
    @file_server = fork { server.start }
    sleep 2
  end

  def stop_file_server
    `kill -9 #{@file_server}`
  end

  def wrap_in_html(string, head = "", body = "")
    html = [%{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">}]
    body = "\n<body#{body}>#{string}</body>\n"
    if head
      html.push "<html>"
      html.push "<head>\n#{head}\n</head>"
      html.push body
      html.push "</html>"
    else
      html.push "<html>#{body}</html>"
    end
    html.push ""
    html.join("\n").squish
  end

  def render_email(template_name)
    email_body = TestMailer.render_template(template_name).body.to_s
    Capybara.string(email_body)
  end
end

RSpec.configure do |config|
  config.include AwesomeMailerTestHelper

  config.before do
    Rails.stub(:configuration) do
      AwesomeMailerTestHelper::AwesomeStruct.new
    end
  end
end
