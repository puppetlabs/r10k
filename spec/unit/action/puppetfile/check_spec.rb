require 'spec_helper'
require 'r10k/action/puppetfile/check'

describe R10K::Action::Puppetfile::Check do

  subject { described_class.new({root: "/some/nonexistent/path"}, []) }

  let(:puppetfile) { instance_double('R10K::Puppetfile') }

  before { allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil).and_return(puppetfile) }

  it "prints 'Syntax OK' when the Puppetfile syntax could be validated" do
    expect(puppetfile).to receive(:load!)
    expect($stderr).to receive(:puts).with("Syntax OK")
    subject.call
  end

  it "prints an error message when validating the Puppetfile syntax raised an error" do
    expect(puppetfile).to receive(:load!).and_raise(R10K::Error.new("Boom!"))
    expect(R10K::Errors::Formatting).to receive(:format_exception).with(instance_of(R10K::Error), anything).and_return("Formatted error message")
    expect($stderr).to receive(:puts).with("Formatted error message")
    subject.call
  end
end
