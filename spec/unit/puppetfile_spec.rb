require 'spec_helper'
require 'r10k/puppetfile'

describe R10K::Puppetfile do

  subject do
    described_class.new(
      '/some/nonexistent/basedir'
    )
  end

  describe "the default moduledir" do
    it "is the basedir joined with '/modules' path" do
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/modules'
    end
  end

  describe "setting moduledir" do
    it "changes to given moduledir if it is an absolute path" do
      subject.set_moduledir('/absolute/path/moduledir')
      expect(subject.moduledir).to eq '/absolute/path/moduledir'
    end

    it "joins the basedir with the given moduledir if it is a relative path" do
      subject.set_moduledir('relative/moduledir')
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/relative/moduledir'
    end
  end

  describe "evaluating a Puppetfile" do
    def expect_wrapped_error(orig, pf_path, wrapped_error)
      expect(orig).to be_a_kind_of(R10K::Error)
      expect(orig.message).to eq("Failed to evaluate #{pf_path}")
      expect(orig.original).to be_a_kind_of(wrapped_error)
    end

    it "wraps and re-raises syntax errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'invalid-syntax')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, SyntaxError)
      end
    end

    it "wraps and re-raises load errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'load-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, LoadError)
      end
    end
  end
end
