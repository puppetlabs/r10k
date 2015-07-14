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
