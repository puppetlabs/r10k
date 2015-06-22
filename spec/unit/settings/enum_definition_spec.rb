require 'spec_helper'
require 'r10k/settings/enum_definition'

describe R10K::Settings::EnumDefinition do

  subject { described_class.new(:enum, :enum => %w[one two three]) }

  describe '#validate' do
    it "doesn't raise an error when given an expected value" do
      subject.assign('two')
      subject.validate
    end
    it "raises an error when given a value outside the enum" do
      subject.assign('dos')
      expect {
        subject.validate
      }.to raise_error(ArgumentError, "Setting enum should be one of #{%w[one two three].inspect}, not 'dos'")
    end
  end
end
