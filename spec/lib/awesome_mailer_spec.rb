require 'spec_helper'

describe AwesomeMailer::Base do
  it "renders messages like ActionMailer::Base" do
    TestMailer.render_template(:basic).should be_instance_of Mail::Message
  end

  it "converts bad HTML to good HTML" do
    expect(render_email(:no_doctype)).to have_text("I have no doctype")
  end

  it "maintains doctypes if given" do
    expect(render_email(:doctype)).to have_css('nav', text: "I have a doctype")
  end

  describe "when the asset pipeline is enabled" do
    before { load_asset_pipeline }

    subject { render_email(:asset_pipeline) }
    it { should have_css('div[style="border: 1px solid #f00"]', text: "welcome!") }

    it "automatically parses the body of multipart emails" do
      expect(subject.text).to match("welcome!")
    end
  end

  describe "url rewriting" do
    before { AwesomeMailer::Base.stub(:default_url_options) { {host: "foo.bar"} } }

    subject { render_email(:url_rewriting) }
    it { should have_xpath("//div[@style='background-image: url(\"http://foo.bar/images/baz.jpg\")']", text: "welcome!") }
  end

  describe "loading remote stylesheets" do
    before { load_file_server }
    after { stop_file_server }

    subject { render_email(:remote_stylesheet) }
    it { should have_xpath(%{//div[@style="background-image: url('http://localhost:9876/images/baz.jpg')"]}) }
  end

  describe "pseudo-states" do
    subject { render_email(:pseudo_with_head) }
    it { should have_text "I have a hover state in <head>" }
    it { should have_text("p:hover { background-color: #f00 }") }
  end

  describe "@import and @font-face styles" do
    subject { render_email(:font_face_with_head) }
    it { should have_xpath(%{//p[@class="chunkfive"][@style="font-family: 'ChunkFive'"]}) }
    it { should have_text("@font-face { font-family: 'ChunkFive'; src: url('../chunkfive.eot') }") }
  end

  describe "embeding @media queries in the head tag" do
    subject { render_email(:media_queries) }
    it { should have_text("Body text") }
    it { should have_text(%{\n@media only screen and (min-width: 600px) {\n body { background-color: #f00 }\n}\n@media only screen and (min-width: 320px) {\n body { background-color: #00f }\n}\n}) }
    it { should have_xpath(%{//body[@style="background-color: #0f0"]}) }
  end

  describe "moving browser-specific properties into the head stylesheet" do
    subject { render_email(:vendor_prefixes) }
    it { should have_xpath(%{//p[@style="border: 1px solid #f00; border-radius: 5px; padding: 1em"]}, text: "Body text") }
    it { should have_text(%{p { -ms-border-radius: 5px; -o-border-radius: 5px; -moz-border-radius: 5px; -webkit-border-radius: 5px }}) }
  end

  describe "moving <style> tags inline" do
    subject { render_email(:embedded_styles) }
    it { should have_xpath(%{//div[@style="border: 1px solid #f00"]}, text: "welcome!") }
  end

  describe "handling advanced selectors" do
    subject { render_email(:advanced_selectors) }

    context "Visible elements" do
      it { should have_xpath(%{//div[@class="neato neater"][@id="hey-hey"][@style="font-size: 100%; margin: 1em; padding: 10px; color: orange"]}) }
      it { should have_xpath(%{//p[@lang="fr"][@style="font-weight: normal; border-color: yellow"]}, text: "First") }
      it { should have_xpath(%{//p[@lang="de en"][@class="bold"][@style="font-weight: normal; border: 1px solid red; border-color: silver; background-color: blue"]}, text: "Second") }
      it { should have_xpath(%{//p[@id="third"][@style="font-weight: normal; display: inline-block; margin-bottom: 1em"]}, text: "Third") }
      it { should have_css("a", text: "I'm a thing") }
    end

    context "Hidden elements" do
      let(:html) { subject.native.inner_html }

      it "has the hidden link" do
        expect(html).to include("I'm a hidden thing")
      end

      it "has the hidden div" do
        expect(html).to include(%{<div style=\"display: none; font-size: 100%\"></div>})
      end

      it "has the hidden check box" do
        expect(html).to include("Do a thing?")
      end
    end

    context "Inline styles" do
      it { should have_text(%{input:not([name=foo]):not(.baz) { font-size: 110% }}) }
      it { should have_text(%{a:link { color: black }}) }
      it { should have_text(%{a:active { top: 1px }}) }
      it { should have_text(%{a:visited { color: purple }}) }
      it { should have_text(%{a:focus { outline: none }}) }
      it { should have_text(%{a:target { background-color: white }}) }
      it { should have_text(%{input:checked { vertical-align: middle }}) }
      it { should have_text(%{p:lang(fr) { font-weight: bold }}) }
      it { should have_text(%{p:before { content: "PARAGRAPH COMIN UP" }}) }
    end

    it { should have_xpath(%{//body[@id="target"][@style="background-color: #0f0"]}) }
  end
end
