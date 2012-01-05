require 'spec_helper'
require 'awesome_mailer'

AwesomeMailer::Base.prepend_view_path 'spec/support'
AwesomeMailer::Base.config.assets_dir = 'spec/support'

class TestMailer < AwesomeMailer::Base
  def test_email(subject = "Hello!")
    mail(
      :from => "flip@x451.com",
      :to => "flip@x451.com",
      :subject => subject
    )
  end

  def test_multipart_email(subject = "Hello")
     mail(
       :from => "flip@x451.com",
       :to => "flip@x451.com",
       :subject => subject
     ) do |format|
      format.html { render :test_email }
      format.text { render :test_email }
    end
  end
end

describe AwesomeMailer::Base do
  it "should render messages like ActionMailer::Base" do
    TestMailer.test_email("Howdy!").should be_instance_of Mail::Message
  end

  it "should automatically parse the body of HTML e-mails" do
    raise TestMailer.test_email("Howdy!").html_part.body.inspect
  end

  it "should automatically parse the body of multipart e-mails" do
    raise TestMailer.test_multipart_email("Howdy!").html_part.body.inspect
  end
end

