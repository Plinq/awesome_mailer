require 'spec_helper'

describe AwesomeMailer::Base do
  it "renders messages like ActionMailer::Base" do
    TestMailer.render_template(:basic).should be_instance_of Mail::Message
  end

  it "converts bad HTML to good HTML" do email = TestMailer.render_template(:no_doctype).body.to_s
    email.should == wrap_in_html("<p>I have no doctype</p>", false)
  end

  describe "when the asset pipeline is enabled" do
    before do
      load_asset_pipeline
    end

    it "automatically parses the body of HTML e-mails" do
      email = TestMailer.render_template(:asset_pipeline).body.to_s
      email.should == wrap_in_html('<div style="border: 1px solid #f00;">welcome!</div>')
    end

    it "automatically parses the body of multipart e-mails" do
      email = TestMailer.render_multipart_template(:asset_pipeline)
      email.html_part.body.to_s.should == wrap_in_html('<div style="border: 1px solid #f00;">welcome!</div>')
      email.text_part.body.to_s.should == "welcome!\n"
    end
  end

  describe "url rewriting" do
    before do
      AwesomeMailer::Base.stub(:default_url_options) { {host: "foo.bar"} }
    end

    it "rewrites URLS in a stylesheet to the default_url_options[:host]" do
      email = TestMailer.render_template(:url_rewriting).body.to_s
      email.should == wrap_in_html(%{<div style='background-image: url("http://foo.bar/images/baz.jpg");'>welcome!</div>})
    end
  end

  describe "loading remote stylesheets" do
    before do

    end

    it "loads the stylesheet from a URL" do
      email = TestMailer.render_template(:remote_stylesheet).body.to_s
      current_path = File.expand_path('../public', File.dirname(__FILE__))
      email.should == wrap_in_html(%{<div style='background-image: url("#{current_path}/images/baz.jpg");'>welcome!</div>})
    end
  end

  describe "pseudo-states" do
    it "adds a style tag to the document head" do
      email = TestMailer.render_template(:pseudo_with_head).body.to_s
      email.should == wrap_in_html(
        %{<p>I have a hover state in &lt;head&gt;</p>},
        %{<style type="text/css">\np:hover { background-color: #f00; }\n</style>}
      )
    end

    it "adds a head tag to the document fragment" do
      email = TestMailer.render_template(:pseudo_without_head).body.to_s
      email.should == wrap_in_html(
        %{<p>I have a hover state in &lt;head&gt;</p>},
        %{<style type="text/css">\np:hover { background-color: #f00; }\n</style>}
      )
    end
  end

  describe "@import and @font-face styles" do
    it "adds a style tag to the document head" do
      email = TestMailer.render_template(:font_face_with_head).body.to_s
      email.should == wrap_in_html(
        %{<p class="chunkfive" style="font-family: 'ChunkFive';">I have a custom font</p>},
        %{<style type="text/css">\n@font-face { font-family: 'ChunkFive'; src: url('../chunkfive.eot'); }\n</style>}
      )
    end

    it "adds a head tag to the document fragment" do
      email = TestMailer.render_template(:font_face_without_head).body.to_s
      email.should == wrap_in_html(
        %{<p class="chunkfive" style="font-family: 'ChunkFive';">I have a custom font</p>},
        %{<style type="text/css">\n@font-face { font-family: 'ChunkFive'; src: url('../chunkfive.eot'); }\n</style>}
      )
    end
  end
end
