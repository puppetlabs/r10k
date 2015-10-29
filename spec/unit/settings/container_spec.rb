require 'spec_helper'

require 'r10k/settings'

describe R10K::Settings::Container do

  describe 'validating keys' do
    it 'can add new valid keys' do
      subject.add_valid_key(:v)
      subject[:v]
    end

    it 'can check if a key is valid' do
      subject.add_valid_key(:v)
      expect(subject.valid_key?(:v)).to be_truthy
    end

    it 'can list all valid keys' do
      subject.add_valid_key(:v)
      subject.add_valid_key(:w)

      expect(subject.valid_keys).to include :v
      expect(subject.valid_keys).to include :w
    end
  end

  describe 'specifying settings' do
    it 'fails if a setting application uses an invalid key' do
      expect { subject[:invalid] = 'fail' }.to raise_error R10K::Settings::Container::InvalidKey
    end

    it 'can look up values that it sets' do
      subject.add_valid_key :v
      subject[:v] = 'set'
      expect(subject[:v]).to eq 'set'
    end
  end

  describe 'looking up settings' do
    before do
      subject.add_valid_key :v
    end

    it 'fails if a setting lookup uses an invalid key' do
      expect { subject[:invalid] }.to raise_error R10K::Settings::Container::InvalidKey
    end

    it 'returns nil if a key is valid but no setting is present' do
      expect(subject[:v]).to be_nil
    end

    describe 'with a parent container' do
      let(:parent) { described_class.new.tap { |p| p.add_valid_key :v } }
      subject { described_class.new(parent) }

      it 'uses its setting over a parent value' do
        subject[:v] = 'child'
        parent[:v] = 'parent'
        expect(subject[:v]).to eq 'child'
      end

      it 'duplicates and stores the parent object to avoid modifying the parent object' do
        parent[:v] = {}
        subject[:v][:hello] = "world"
        expect(subject[:v]).to eq({hello: "world"})
        expect(parent[:v]).to eq({})
      end

      it 'falls back to the parent value if it does not have a value' do
        parent[:v] = 'parent'
        expect(subject[:v]).to eq 'parent'
      end
    end
  end

  describe "resetting" do
    before do
      subject.add_valid_key :v
    end

    it "unsets all settings" do
      subject[:v] = "hi"
      subject.reset!
      expect(subject[:v]).to be_nil
    end

    it "doesn't remove valid values" do
      subject.reset!
      expect(subject.valid_key?(:v)).to be_truthy
    end
  end
end
