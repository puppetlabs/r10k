require 'spec_helper'
require 'r10k/settings/collection'
require 'r10k/settings/definition'

describe R10K::Settings::Collection do

  let(:symbol_defn) { R10K::Settings::Definition.new(:symbol_defn, :validate => lambda { |x| raise TypeError unless x.is_a?(Symbol) }) }
  let(:default_defn) { R10K::Settings::Definition.new(:default_defn, :default => lambda { "Defaults are fun" }) }

  subject do
    described_class.new(:collection, [symbol_defn, default_defn])
  end

  describe '#assign' do
    it "assigns values to the appropriate setting" do
      subject.assign({:symbol_defn => :hello})
      expect(symbol_defn.value).to eq :hello
    end

    it "can accept invalid settings" do
      subject.assign({:hardly_a_setting => "nope nope nope"})
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
