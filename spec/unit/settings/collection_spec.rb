require 'spec_helper'
require 'r10k/settings/collection'
require 'r10k/settings/definition'

describe R10K::Settings::Collection do

  let(:symbol_defn) { R10K::Settings::Definition.new(:symbol_defn, :validate => lambda { |x| raise TypeError unless x.is_a?(Symbol) }) }
  let(:default_defn) { R10K::Settings::Definition.new(:default_defn, :default => lambda { "Defaults are fun" }) }

  subject do
    described_class.new(:collection, [symbol_defn, default_defn])
  end

  describe "#evaluate" do
    it "assigns values, validates them, and resolves a final value" do
      expect(subject).to receive(:assign).with({:default_defn => :squid})
      expect(subject).to receive(:validate)
      expect(subject).to receive(:resolve)
      subject.evaluate({:default_defn => :squid})
    end
  end


  describe '#assign' do
    it "assigns values to the appropriate setting" do
      subject.assign({:symbol_defn => :hello})
      expect(symbol_defn.value).to eq :hello
    end

    it "can accept invalid settings" do
      subject.assign({:hardly_a_setting => "nope nope nope"})
    end

    it "silently ignores attempts to assign nil" do
      subject.assign(nil)
    end
  end

  describe '#validate' do
    it "raises an error containing a hash of nested validation errors" do
      subject.assign({:symbol_defn => "Definitely not a symbol"})
      expect {
        errors = subject.validate
      }.to raise_error do |error|
        expect(error).to be_a_kind_of(R10K::Settings::Collection::ValidationError)
        errors = error.errors
        expect(errors.size).to eq 1
        expect(errors[:symbol_defn]).to be_a_kind_of(TypeError)
      end
    end

    it "it does not raise an error if no errors were found" do
      subject.assign({:default_defn => "yep"})
      expect(subject.validate).to be_nil
    end
  end

  describe '#resolve' do
    it "returns a frozen hash of all settings" do
      subject.assign({:symbol_defn => :some_value})
      rv = subject.resolve
      expect(rv).to be_frozen
      expect(rv).to eq({:symbol_defn => :some_value, :default_defn => "Defaults are fun"})
    end
  end
end

describe R10K::Settings::Collection::ValidationError do


  let(:flat_errors) do
    described_class.new("Validation failures for some group", errors: {
      some_defn: ArgumentError.new("some_defn is wrong, somehow."),
      uri_setting: ArgumentError.new("uri_setting NOTAURI is not a URI.")
    })
  end

  let(:flat_error_text) do
    [
      "Validation failures for some group:",
      "    some_defn:",
      "        some_defn is wrong, somehow.",
      "    uri_setting:",
      "        uri_setting NOTAURI is not a URI."]
    .join("\n")
  end

  let(:nested_errors) do
    described_class.new("Validation failures for some nesting group", errors: {
      file_setting: ArgumentError.new("file_setting is a potato, not a file."),
      nested: flat_errors
    })
  end

  let(:nested_error_text) do
    [
      "Validation failures for some nesting group:",
      "    file_setting:",
      "        file_setting is a potato, not a file.",
      "    nested:",
      "        Validation failures for some group:",
      "            some_defn:",
      "                some_defn is wrong, somehow.",
      "            uri_setting:",
      "                uri_setting NOTAURI is not a URI."
    ].join("\n")
  end

  describe "formatting a human readable error message" do
    describe "no with no nested validation errors" do
      it "generates a human readable set of validation errors." do
        expect(flat_errors.format).to eq flat_error_text
      end
    end

    describe "with nested validation errors" do
      it "generates a human readable set of validation errors." do
        expect(nested_errors.format).to eq nested_error_text
      end
    end
  end
end
