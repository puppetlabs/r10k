require 'spec_helper'
require 'r10k/settings/path_definition'

describe R10K::Settings::PathDefinition do

  describe '#initialize' do
    [:readable, :writable].each do |setting|
      it "accepts the #{setting} option" do
        subject = described_class.new(:setting, setting => true)
        expect(subject.send(setting)).to eq true
      end
    end
  end

  describe '#set' do
    [:readable, :writable].each do |setting|
      it "raises an error when #{setting} is true and the path is not readable" do
        subject = described_class.new(:setting, setting => true)
        expect(File).to receive("#{setting}?".to_sym).with('/some/path').and_return false
        expect {
          subject.set('/some/path')
        }.to raise_error(ArgumentError, "/some/path is not #{setting}")
      end
    end
  end
end
