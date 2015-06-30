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

  describe '#assign' do
    it "sets each setting name/value pair" do
      subject.assign({:somedefn => "bulk assigned value"})
      expect(subject.get(:somedefn)).to eq "bulk assigned value"
    end

    it "converts string keys to symbol keys when assigning" do
      subject.assign({'somedefn' => "string keyed value"})
      expect(subject.get(:somedefn)).to eq "string keyed value"
    end

    it "raises an error if an invalid setting was given" do
      expect {
        subject.assign({:invalid => "bulk assigned value"})
      }.to raise_error(ArgumentError, "Cannot set value of nonexistent setting invalid")
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

  describe '#assign' do
    it "recursively sets each setting name/value pair" do
      subject.assign({:toplevel_defn => "top level value", :nested => {:nested_defn => "nested value"}})
      expect(subject[:toplevel_defn]).to eq 'top level value'
      expect(subject[:nested][:nested_defn]).to eq 'nested value'
    end
  end
end

describe R10K::Settings::Collection, "with apply hooks" do

  let(:collector) { Hash.new }

  subject do
    described_class.new(
      :toplevel, [R10K::Settings::Definition.new(:toplevel_defn, :apply => lambda { |_| collector[:toplevel_defn] = 'set'})],
      [
        described_class.new(
          :nested,
          [R10K::Settings::Definition.new(:nested_defn, :apply => lambda { |_| collector[:nested_defn] = 'also set' })]
        )
      ]
    )
  end

  describe '#apply!' do
    it "calls #apply! on all definitions" do
      subject.apply!
      expect(collector[:toplevel_defn]).to eq 'set'
    end

    it "calls #apply! on all nested collections" do
      subject.apply!
      expect(collector[:nested_defn]).to eq 'also set'
    end
  end
end
