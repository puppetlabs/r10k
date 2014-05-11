require 'spec_helper'
require 'r10k/keyed_factory'

describe R10K::KeyedFactory do

  let(:registered) { Class.new }

  describe "registering implementations" do
    it "can register new implementations" do
      subject.register(:klass, registered)
      expect(subject.retrieve(:klass)).to eq registered
    end

    it "raises an error when a duplicate implementation is registered" do
      subject.register(:klass, registered)

      expect {
        subject.register(:klass, registered)
      }.to raise_error(R10K::KeyedFactory::DuplicateImplementationError)
    end

    it "can register classes with nil as a key" do
      subject.register(nil, registered)
      expect(subject.retrieve(nil)).to eq registered
    end
  end

  describe "generating instances" do
    before do
      subject.register(:klass, registered)
    end

    it "generates an instance with the associated class" do
      instance = subject.generate(:klass)
      expect(instance).to be_a_kind_of registered
    end

    it "can generate a class with nil as a key" do
      other = Class.new
      subject.register(nil, other)
      instance = subject.generate(nil)
      expect(instance).to be_a_kind_of other
    end

    it "raises an error if no implementation was registered with the given key" do
      expect {
        subject.generate(:foo)
      }.to raise_error(R10K::KeyedFactory::UnknownImplementationError)
    end
  end
end
