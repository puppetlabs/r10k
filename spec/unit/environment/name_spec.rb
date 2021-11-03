require 'spec_helper'
require 'r10k/environment/name'

describe R10K::Environment::Name do
  describe "strip_component" do
    it "does not modify the given name when no strip_component is given" do
      bn = described_class.new('myenv', source: 'source', prefix: false)
      expect(bn.dirname).to eq 'myenv'
      expect(bn.name).to eq 'myenv'
      expect(bn.ref).to eq 'myenv'
    end

    it "removes the first occurance of a regex match when a regex is given" do
      bn = described_class.new('myenv', source: 'source', prefix: false, strip_component: '/env/')
      expect(bn.dirname).to eq 'my'
      expect(bn.name).to eq 'my'
      expect(bn.ref).to eq 'myenv'
    end

    it "does not modify the given name when there is no regex match" do
      bn = described_class.new('myenv', source: 'source', prefix: false, strip_component: '/bar/')
      expect(bn.dirname).to eq 'myenv'
      expect(bn.name).to eq 'myenv'
      expect(bn.ref).to eq 'myenv'
    end

    it "removes the given name's prefix when it matches strip_component" do
      bn = described_class.new('env/prod', source: 'source', prefix: false, strip_component: 'env/')
      expect(bn.dirname).to eq 'prod'
      expect(bn.name).to eq 'prod'
      expect(bn.ref).to eq 'env/prod'
    end

    it "raises an error when given an integer" do
      expect {
        described_class.new('env/prod', source: 'source', prefix: false, strip_component: 4)
      }.to raise_error(%r{Improper.*"4"})
    end
  end

  describe "prefixing" do
    it "uses the branch name as the dirname when prefixing is off" do
      bn = described_class.new('mybranch', :source => 'source', :prefix => false)
      expect(bn.dirname).to eq 'mybranch'
      expect(bn.name).to eq 'mybranch'
      expect(bn.ref).to eq 'mybranch'
    end

    it "prepends the source name when prefixing is on" do
      bn = described_class.new('mybranch', :source => 'source', :prefix => true)
      expect(bn.dirname).to eq 'source_mybranch'
      expect(bn.name).to eq 'mybranch'
      expect(bn.ref).to eq 'mybranch'
    end

    it "prepends the prefix name when prefixing is overridden" do
      bn = described_class.new('mybranch', {:prefix => "bar", :sourcename => 'foo'})
      expect(bn.dirname).to eq 'bar_mybranch'
      expect(bn.name).to eq 'mybranch'
      expect(bn.ref).to eq 'mybranch'
    end

    it "uses the branch name as the dirname when prefixing is nil" do
      bn = described_class.new('mybranch', {:prefix => nil, :sourcename => 'foo'})
      expect(bn.dirname).to eq 'mybranch'
      expect(bn.name).to eq 'mybranch'
      expect(bn.ref).to eq 'mybranch'
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
          expect(bn.name).to eq branch
          expect(bn.ref).to eq branch
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
