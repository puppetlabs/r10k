require 'spec_helper'

require 'r10k/settings/collection'
require 'r10k/settings/list'

shared_examples_for "a setting with ancestors" do
  describe '#parent=' do
    it "allows assignment to a collection" do
      parent = R10K::Settings::Collection.new(:parent, [])

      subject.parent = parent

      expect(subject.parent).to eq parent
    end

    it "allows assignment to a list" do
      parent = R10K::Settings::List.new(:parent, [])

      subject.parent = parent

      expect(subject.parent).to eq parent
    end

    it "rejects assignment when argument is not a settings collection or list" do
      parent = Hash.new

      expect { subject.parent = parent }.to raise_error do |error|
        expect(error.message).to match /may only belong to a settings collection or list/i
      end
    end

    it "rejects re-assignment" do
      parent = R10K::Settings::Collection.new(:parent, [])
      step_parent = R10K::Settings::Collection.new(:step_parent, [])

      subject.parent = parent

      expect { subject.parent = step_parent }.to raise_error do |error|
        expect(error.message).to match /cannot be reassigned.*new parent/i
      end
    end
  end
end

