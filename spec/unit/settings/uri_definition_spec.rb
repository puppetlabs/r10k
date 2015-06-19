require 'spec_helper'
require 'r10k/settings/uri_definition'

describe R10K::Settings::URIDefinition do

  subject { described_class.new(:uri) }

  it "passes validation if a value has not been set" do
    expect(subject.validate).to be_nil
  end

  it "passes validation when given a valid url" do
    subject.assign("http://definitely.a/url")
    expect(subject.validate).to be_nil
  end

  it "raises an error when given an invalid URL" do
    subject.assign("That's no URI!")
    expect {
      subject.validate
    }.to raise_error(ArgumentError, "Setting uri requires a URL but 'That's no URI!' could not be parsed as a URL")
  end
end
