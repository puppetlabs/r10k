require 'spec_helper'
require 'r10k/settings/definition'

describe R10K::Settings::Definition do
  describe "#evaluate" do
    it "assigns a value, validates it, and resolves a final value" do
      subject = described_class.new(:setting)
      expect(subject).to receive(:assign).with("myvalue")
      expect(subject).to receive(:validate)
      expect(subject).to receive(:resolve)
      subject.evaluate("myvalue")
    end
  end

  describe "#assign" do
    it 'stores the provided value' do
      subject = described_class.new(:setting)
      subject.assign("I'm the value")
      expect(subject.value).to eq "I'm the value"
    end

    it "normalizes the stored value when a normalize hook is set" do
      subject = described_class.new(:setting, :normalize => lambda { |input| input.to_sym })
      subject.assign("symbolizeme")
      expect(subject.value).to eq :symbolizeme
    end
  end

  describe "#validate" do
    it "does nothing if a value has not been assigned" do
      subject = described_class.new(:setting, :validate => lambda { |_| raise "Shouldn't be called" })
      subject.validate
    end

    it "does nothing if a validate hook has not been assigned" do
      subject = described_class.new(:setting)
      subject.assign("I'm the value")
      subject.validate
    end

    it "raises up errors raised from the validate hook" do
      subject = described_class.new(:satellite, :validate => lambda { |input| raise ArgumentError, "Invalid value #{input}: that's no moon!" })
      subject.assign("Alderaan")
      expect {
        subject.validate
      }.to raise_error(ArgumentError, "Invalid value Alderaan: that's no moon!")
    end

    it "returns if the validate hook did not raise an error" do
      subject = described_class.new(:setting, :validate => lambda { |_| "That's a moon" })
      subject.assign("Mun")
      subject.validate
    end
  end

  describe "#resolve" do
    it "returns the value when the value has been given" do
      subject = described_class.new(:setting)
      subject.assign("Mun")
      expect(subject.resolve).to eq "Mun"
    end

    it "resolves the default when the default is a proc" do
      subject = described_class.new(:setting, :default => lambda { "Minmus" })
      expect(subject.resolve).to eq "Minmus"
    end

    it "returns the default when the default is not a proc" do
      subject = described_class.new(:setting, :default => "Ike")
      expect(subject.resolve).to eq "Ike"
    end

    it "returns nil when there is no value nor default" do
      subject = described_class.new(:setting)
      expect(subject.resolve).to be_nil
    end
  end
end
