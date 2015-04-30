require 'spec_helper'
require 'r10k/settings/definition'

describe R10K::Settings::Definition do
  describe "#initialize" do
    it 'accepts the :desc option' do
      subject = described_class.new(:setting, :desc => "I'm a description")
      expect(subject.desc).to eq "I'm a description"
    end

    it 'accepts the :default option' do
      subject = described_class.new(:setting, :default => "I'm a default")
      expect(subject.default).to eq "I'm a default"
    end

    it 'accepts the :validate option' do
      blk = lambda { "I'm a lambda" }
      subject = described_class.new(:setting, :validate => blk)
      expect(subject.validate).to eq blk
    end
  end

  describe "#set" do
    it 'stores the provided value' do
      subject = described_class.new(:setting)
      subject.set("I'm the value")
      expect(subject.value).to eq "I'm the value"
    end

    it 'calls the validate hook when given' do
      subject = described_class.new(:setting, :validate => lambda { |_| raise ArgumentError, "Validation failed" })
      expect {
        subject.set("I'm the value")
      }.to raise_error(ArgumentError, "Validation failed")
    end
  end

  describe "#get" do
    it 'returns the value when set' do
      subject = described_class.new(:setting)
      subject.set("I'm the value")
      expect(subject.get).to eq "I'm the value"
    end

    it 'returns the default when the default is not a proc' do
      default = Object.new
      subject = described_class.new(:setting, :default => default)
      expect(subject.get).to eq default
    end

    it 'returns the result of the default when the default is a proc' do
      subject = described_class.new(:setting, :default => lambda { "I'm the result of the default lambda" })
      expect(subject.get).to eq "I'm the result of the default lambda"
    end
  end
end
