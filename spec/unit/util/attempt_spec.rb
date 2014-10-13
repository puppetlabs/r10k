require 'spec_helper'
require 'r10k/util/attempt'

describe R10K::Util::Attempt do

  describe "with a single truthy value" do
    subject(:attempt) { described_class.new("hello") }

    it "invokes the next action with the value" do
      value = nil
      attempt.try { |inner| value = inner }
      attempt.run
      expect(attempt).to be_ok
      expect(value).to eq "hello"
    end

    it "returns the resulting value from the block" do
      attempt.try { |inner| inner + " world" }
      result = attempt.run
      expect(attempt).to be_ok
      expect(result).to eq "hello world"
    end
  end

  describe "with a false value" do
    subject(:attempt) { described_class.new(nil) }

    it "does not evaluate the block" do
      value = "outside of block"
      attempt.try { |inner| value = "ran block" }
      attempt.run
      expect(attempt).to be_ok
      expect(value).to eq "outside of block"
    end

    it "does not continue execution" do
      attempt.try { |_| "something" }.try { raise }
      expect(attempt.run).to be_nil
    end
  end

  describe "with an array" do
    subject(:attempt) { described_class.new([1, 2, 3, 4, 5]) }

    it "runs the block for each element in the array" do
      sum = 0
      attempt.try { |inner| sum += inner }
      attempt.run
      expect(attempt).to be_ok
      expect(sum).to eq 15
    end

    it "returns the result of the operation on each array member" do
      sum = 0
      attempt.try { |inner| sum += inner }
      result = attempt.run
      expect(result).to eq([1, 3, 6, 10, 15])
    end
  end

  describe "when an exception is raised" do
    subject(:attempt) { described_class.new("initial") }

    it "returns the exception" do
      attempt.try { |_| raise RuntimeError }
      result = attempt.run
      expect(attempt).to_not be_ok
      expect(result).to be_a_kind_of RuntimeError
    end

    it "does not continue execution" do
      attempt.try { |_| raise RuntimeError }.try { |_| "This should not be run" }
      result = attempt.run
      expect(result).to be_a_kind_of RuntimeError
    end

    it "only rescues descendants of StandardError" do
      attempt.try { |_| raise Exception }
      expect { attempt.run }.to raise_error
    end
  end
end
