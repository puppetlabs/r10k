require 'spec_helper'
require 'r10k/settings/enum_definition'

describe R10K::Settings::EnumDefinition do
  describe '#initialize' do
    it 'accepts the :enum option' do
      subject = described_class.new(:setting, :enum => ['one', 'two'])
      expect(subject.enum).to eq ['one', 'two']
    end
  end

  describe '#set' do
    subject { described_class.new(:setting, :enum => ['one', 'two']) }
    it 'raises an error if the new value is not in the enum' do
      expect {
        subject.set('three')
      }.to raise_error(ArgumentError, "Definition setting expects one of #{['one', 'two'].inspect}, got \"three\"")
    end

    it "doesn't raise an error if the new value is in the enum" do
      subject.set('two')
      expect(subject.value).to eq 'two'
    end
  end
end
