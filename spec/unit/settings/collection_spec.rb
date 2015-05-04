require 'spec_helper'
require 'r10k/settings/definition'
require 'r10k/settings/collection'

describe R10K::Settings::Collection do

  let(:definition_list) do
    [R10K::Settings::Definition.new(:somedefn, :default => lambda { |defn| "default value: #{defn.name}" })]
  end

  subject { described_class.new(:somecollection, definition_list) }

  describe '#initialize' do
    it 'sets itself as the collection of each definition' do
      expect(subject.definitions[:somedefn].collection).to eq subject
    end
  end

  describe '#get' do
    it 'returns the definition value when the definition exists' do
      expect(subject.get(:somedefn)).to eq "default value: somedefn"
    end

    it "raises an exception when the definition doesn't exist" do
      expect {
        subject.get(:nosetting)
      }.to raise_error(ArgumentError, "Cannot get value of nonexistent setting nosetting")
    end
  end

  describe '#set' do
    it 'sets the definition value when the definition exists' do
      subject.set(:somedefn, :newvalue)
      expect(subject.definitions[:somedefn].value).to eq :newvalue
    end

    it "raises an exception when the definition doesn't exist" do
      expect {
        subject.set(:nosetting, :nope)
      }.to raise_error(ArgumentError, "Cannot set value of nonexistent setting nosetting")
    end
  end
end

describe R10K::Settings::Collection, "with a nested collection" do

  subject do
    described_class.new(
      :toplevel, [R10K::Settings::Definition.new(:toplevel_defn, :default => lambda { |defn| "default value: #{defn.name}" })],
      [
        described_class.new(
          :nested,
          [R10K::Settings::Definition.new(:nested_defn, :default => lambda { |defn| "#{defn.collection.parent.get(:toplevel_defn)} + nested" })]
        )
      ]
    )
  end

  it 'links up nested collections and definitions' do
    expect(subject.get(:nested).get(:nested_defn)).to eq "default value: toplevel_defn + nested"
  end

  describe '#get' do
    it 'returns the collection with that name' do
      expect(subject.get(:nested)).to eq subject.collections[:nested]
    end
  end

  describe '#set' do
    it 'raises an error when trying to replace a collection' do
      expect {
        subject.set(:nested, Object.new)
      }.to raise_error(ArgumentError, "Cannot set value of nested collection nested; set individual values on the nested collection instead.")
    end
  end
end
