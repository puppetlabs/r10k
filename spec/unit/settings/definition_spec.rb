require 'spec_helper'
require 'r10k/settings/definition'

describe R10K::Settings::Definition do
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
