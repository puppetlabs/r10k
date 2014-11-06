require 'spec_helper'
require 'r10k/source'

describe R10K::Source::Base do
  subject { described_class.new('base', '/some/nonexistent/path') }

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:source, subject)
      subject.accept(visitor)
    end

    it "passes the visitor to each environment if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :source
        expect(other).to eq subject
        block.call
      end

      env1 = spy('environment')
      expect(env1).to receive(:accept).with(visitor)
      env2 = spy('environment')
      expect(env2).to receive(:accept).with(visitor)

      expect(subject).to receive(:environments).and_return([env1, env2])
      subject.accept(visitor)
    end
  end
end
