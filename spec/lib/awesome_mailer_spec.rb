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
      email.should == wrap_in_html('<div style="border: 1px solid #f00">welcome!</div>')
    end

    it "automatically parses the body of multipart e-mails" do
      email = TestMailer.render_multipart_template(:asset_pipeline)
      email.html_part.body.to_s.should == wrap_in_html('<div style="border: 1px solid #f00">welcome!</div>')
      email.text_part.body.to_s.should == "welcome!\n"
    end
  end

  describe "url rewriting" do
    before do
      AwesomeMailer::Base.stub(:default_url_options) { {host: "foo.bar"} }
    end

    it "rewrites URLS in a stylesheet to the default_url_options[:host]" do
      email = TestMailer.render_template(:url_rewriting).body.to_s
      email.should == wrap_in_html(%{<div style='background-image: url("http://foo.bar/images/baz.jpg")'>welcome!</div>})
    end
  end

  describe "loading remote stylesheets" do
    before do
      load_file_server
    end

    after do
      stop_file_server
    end

    it "loads the stylesheet from a URL" do
      email = TestMailer.render_template(:remote_stylesheet).body.to_s
      email.should == wrap_in_html(%{<div style="background-image: url('http://localhost:9876/images/baz.jpg')">welcome!</div>})
    end
  end

  describe "pseudo-states" do
    it "adds a style tag to the document head" do
      email = TestMailer.render_template(:pseudo_with_head).body.to_s
      email.should == wrap_in_html(
        %{<p>I have a hover state in &lt;head&gt;</p>},
        %{<style type="text/css">\np:hover { background-color: #f00 }\n</style>}
      )
    end

    it "adds a head tag to the document fragment" do
      email = TestMailer.render_template(:pseudo_without_head).body.to_s
      email.should == wrap_in_html(
        %{<p>I have a hover state in &lt;head&gt;</p>},
        %{<style type="text/css">\np:hover { background-color: #f00 }\n</style>}
      )
    end
  end

  describe "@import and @font-face styles" do
    it "adds a style tag to the document head" do
      email = TestMailer.render_template(:font_face_with_head).body.to_s
      email.should == wrap_in_html(
        %{<p class="chunkfive" style="font-family: 'ChunkFive'">I have a custom font</p>},
        %{<style type="text/css">\n@font-face { font-family: 'ChunkFive'; src: url('../chunkfive.eot') }\n</style>}
      )
    end

    it "adds a head tag to the document fragment" do
      email = TestMailer.render_template(:font_face_without_head).body.to_s
      email.should == wrap_in_html(
        %{<p class="chunkfive" style="font-family: 'ChunkFive'">I have a custom font</p>},
        %{<style type="text/css">\n@font-face { font-family: 'ChunkFive'; src: url('../chunkfive.eot') }\n</style>}
      )
    end
  end

  it "embeds @media queries in the head tag" do
    email = TestMailer.render_template(:media_queries).body.to_s
    email.should == wrap_in_html(
      %{<p>Body text</p>},
      %{<style type=\"text/css\">\n@media only screen and (min-width: 600px) {\n  body { background-color: #f00 }\n}\n@media only screen and (min-width: 320px) {\n  body { background-color: #00f }\n}\n</style>},
      %{ style="background-color: #0f0"}
    )
  end

  it "moves browser-specific properties into the head stylesheet" do
    email = TestMailer.render_template(:vendor_prefixes).body.to_s
    email.should == wrap_in_html(
      %{<p style="border: 1px solid #f00; border-radius: 5px; padding: 1em">Body text</p>},
      %{<style type=\"text/css\">\np { -ms-border-radius: 5px; -o-border-radius: 5px; -moz-border-radius: 5px; -webkit-border-radius: 5px }\n</style>}
    )
  end

  it "moves <style> tags inline" do
    email = TestMailer.render_template(:embedded_styles).body.to_s
    email.should == wrap_in_html('<div style="border: 1px solid #f00">welcome!</div>')
  end

  # TODO: SPLIT THIS UP IT'S AWFUL
  it "handles advanced selectors" do
    email = TestMailer.render_template(:advanced_selectors).body.to_s
    email.should == wrap_in_html(
      %{
    <div class="neato neater" id="hey-hey" style="font-size: 100%; margin: 1em; padding: 10px; color: orange">
      <p lang="fr" style="font-weight: normal; border-color: yellow">First</p>
      <p lang="de en" class="bold" style="font-weight: normal; border: 1px solid red; border-color: silver; background-color: blue">Second</p>
      <p id="third" style="font-weight: normal; display: inline-block; margin-bottom: 1em">Third</p>
      <a>I'm a thing.</a>
      <a href="#" style="display: none">I'm a different thing.</a>
    </div>
    <div style="display: none; font-size: 100%"></div>
    <input checked name="do_thing" type="checkbox" value="1" style="display: none"> Do a thing?
  }, %{<style type="text/css">
input:not([name=foo]):not(.baz) { font-size: 110% }
a:link { color: black }
a:active { top: 1px }
a:hover { text-decoration: underline }
a:visited { color: purple }
a:focus { outline: none }
a:target { background-color: white }
input:checked { vertical-align: middle }
p:lang(fr) { font-weight: bold }
</style>},
  %{ id="target" style="background-color: #0f0"})
  end
end
