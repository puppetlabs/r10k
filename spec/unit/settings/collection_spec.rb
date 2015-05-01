require 'spec_helper'
require 'r10k/settings/definition'
require 'r10k/settings/collection'

describe R10K::Settings::Collection do

  let(:definition_list) do
    [
      R10K::Settings::Definition.new(:somedefn, :default => lambda { |defn| "default value: #{defn.name}" })
    ]
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
