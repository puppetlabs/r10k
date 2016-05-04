require 'spec_helper'
require 'r10k/settings/list'
require 'r10k/settings/collection'
require 'r10k/settings/definition'
require 'r10k/settings/uri_definition'

describe R10K::Settings::List do
  let(:item_proc) do
    lambda { R10K::Settings::URIDefinition.new(nil, { :desc => "A URI in a list" }) }
  end

  subject do
    described_class.new(:test_list, item_proc, { :desc => "A test setting list" })
  end

  it_behaves_like "a setting with ancestors"

  describe '#assign' do
    it "calls item_proc for each item assigned" do
      expect(R10K::Settings::URIDefinition).to receive(:new).and_call_original.exactly(3).times

      subject.assign([ "uri_1", "uri_2", "uri_3"])
    end

    it "claims ownership of newly added items" do
      subject.assign([ "uri_1", "uri_2", "uri_3"])

      item_parents = subject.instance_variable_get(:@items).collect { |i| i.parent }
      expect(item_parents).to all(eq subject)
    end

    it "assigns value to each item" do
      new_values = [ "uri_1", "uri_2", "uri_3"]
      subject.assign(new_values)

      item_values = subject.instance_variable_get(:@items).collect { |i| i.value }
      expect(item_values).to eq new_values
    end

    it "silently ignores attempts to assign nil" do
      subject.assign(nil)
    end
  end

  describe '#validate' do
    it "raises an error containing a list of every item with validation errors" do
      subject.assign([ "uri 1", "uri 2", "http://www.example.com"])

      expect { subject.validate }.to raise_error do |error|
        expect(error).to be_a_kind_of(R10K::Settings::List::ValidationError)
        errors = error.errors.collect { |key, val| val }
        expect(errors.size).to eq 2
        expect(errors).to all(be_a_kind_of(ArgumentError))
        expect(errors.collect { |e| e.message }).to all(match /requires a URL.*could not be parsed/i)
      end
    end

    it "it does not raise an error if no errors were found" do
      subject.assign([ "http://www.example.com" ])
      expect(subject.validate).to be_nil
    end
  end

  describe '#resolve' do
    it "returns a frozen list of all items" do
      subject.assign([ "uri_1", "uri_2" ])

      rv = subject.resolve

      expect(rv).to be_frozen
      expect(rv).to eq([ "uri_1", "uri_2" ])
    end
  end
end

describe R10K::Settings::List::ValidationError do
  subject do
    described_class.new("Sample List Validation Errors", errors: {
      2 => ArgumentError.new("Sample List Item Error"),
    })
  end

  it "generates a human readable error message for the invalid item" do
    message = subject.format

    expect(message).to match /sample list validation errors.*item 2.*sample list item error/im
  end
end
