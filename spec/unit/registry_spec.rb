require 'spec_helper'

require 'r10k/registry'

describe R10K::Registry do

  describe "setting up a new registry" do
    let(:klass) do
      dubs = double('test class')
      allow(dubs).to receive(:new) { |*args| args }
      dubs
    end

    it "can create new objects" do
      registry = described_class.new(klass)
      expect(registry.generate).to eq []
    end

    describe "defining object arity" do

      it "handles unary objects" do
        expect(klass).to receive(:new).with(:foo)

        registry = described_class.new(klass)
        expect(registry.generate(:foo)).to eq [:foo]
      end

      it "handles ternary objects" do
        expect(klass).to receive(:new).with(:foo, :bar, :baz)

        registry = described_class.new(klass)
        expect(registry.generate(:foo, :bar, :baz)).to eq [:foo, :bar, :baz]
      end

      it 'handles n-ary objects' do
        args = %w[a bunch of arbitrary objects]
        expect(klass).to receive(:new).with(*args)

        registry = described_class.new(klass)
        expect(registry.generate(*args)).to eq args
      end

      it 'fails when the required arguments are not matched' do
        expect(klass).to receive(:new).and_raise ArgumentError, "not enough args"

        registry = described_class.new(klass)
        expect { registry.generate('arity is hard') }.to raise_error ArgumentError, "not enough args"
      end
    end

    it "can specify the constructor method" do
      expect(klass).to receive(:from_json).and_return "this is json, right?"

      registry = described_class.new(klass, :from_json)
      expect(registry.generate).to eq "this is json, right?"
    end
  end


  it "returns a memoized object if it's been created before" do
    registry = described_class.new(String)
    first = registry.generate "bam!"
    second = registry.generate "bam!"

    expect(first.object_id).to eq second.object_id
  end

  it 'can clear registered objects' do
    registry = described_class.new(String)

    first = registry.generate "bam!"
    registry.clear!
    second = registry.generate "bam!"

    expect(first.object_id).to_not eq second.object_id

  end
end
