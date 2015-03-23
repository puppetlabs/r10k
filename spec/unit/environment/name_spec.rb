require 'spec_helper'
require 'r10k/environment/name'

describe R10K::Environment::Name do
  describe "prefixing" do
    it "uses the branch name as the dirname when prefixing is off" do
      bn = described_class.new('mybranch', :source => 'source', :prefix => false)
      expect(bn.dirname).to eq 'mybranch'
    end

    it "prepends the source name when prefixing is on" do
      bn = described_class.new('mybranch', :source => 'source', :prefix => true)
      expect(bn.dirname).to eq 'source_mybranch'
    end

    it "prepends the prefix name when prefixing is overridden" do
      bn = described_class.new('mybranch', {:prefix => "bar", :sourcename => 'foo'})
      expect(bn.dirname).to eq 'bar_mybranch'
    end

    it "uses the branch name as the dirname when prefixing is nil" do
      bn = described_class.new('mybranch', {:prefix => nil, :sourcename => 'foo'})
      expect(bn.dirname).to eq 'mybranch'
    end
  end

  describe "determining the validate behavior with :invalid" do
    [
      ['correct_and_warn', {:validate => true, :correct => true}],
      ['correct',          {:validate => false, :correct => true}],
      ['error',            {:validate => true, :correct => false}],
    ].each do |(setting, outcome)|
      it "treats #{setting} as #{outcome.inspect}" do
        bn = described_class.new('mybranch', :source => 'source', :invalid => setting)
        expect(bn.validate?).to eq outcome[:validate]
        expect(bn.correct?).to eq outcome[:correct]
      end
    end
  end

  describe "determining if a branch is a valid environment name" do
    invalid_cases = [
      'hyphenated-branch',
      'dotted.branch',
      'slashed/branch',
      'at@branch',
      'http://branch'
    ]

    valid_cases = [
      'my_branchname',
      'my_issue_346',
    ]

    describe "and validate is false" do
      invalid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => false})
          expect(bn).to be_valid
        end
      end

      valid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => false})
          expect(bn).to be_valid
        end
      end
    end

    describe "and validate is true" do
      invalid_cases.each do |branch|
        it "is invalid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => true})
          expect(bn).to_not be_valid
        end
      end

      valid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => true})
          expect(bn).to be_valid
        end
      end

    end
  end

  describe "correcting branch names" do
    invalid_cases = [
      'hyphenated-branch',
      'dotted.branch',
      'slashed/branch',
      'at@branch',
      'http://branch'
    ]

    valid_cases = [
      'my_branchname',
      'my_issue_346',
    ]

    describe "and correct is false" do
      invalid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => false})
          expect(bn.dirname).to eq branch
        end
      end

      valid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => false})
          expect(bn.dirname).to eq branch
        end
      end
    end

    describe "and correct is true" do
      invalid_cases.each do |branch|
        it "replaces invalid characters in #{branch} with underscores" do
          bn = described_class.new(branch.dup, {:correct => true})
          expect(bn.dirname).to eq branch.gsub(/\W/, '_')
        end
      end

      valid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => true})
          expect(bn.dirname).to eq branch
        end
      end
    end
  end
end
