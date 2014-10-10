require 'spec_helper'
require 'r10k/util/setopts'

describe R10K::Util::Setopts do
  let(:klass) do
    Class.new do
      include R10K::Util::Setopts

      attr_reader :valid, :alsovalid

      def initialize(opts = {})
        setopts(opts, [:valid, :alsovalid])
      end
    end
  end

  it "can handle an empty hash of options" do
    o = klass.new()
    expect(o.valid).to be_nil
    expect(o.alsovalid).to be_nil
  end

  it "can handle a single valid option" do
    o = klass.new(:valid => 'yep')
    expect(o.valid).to eq 'yep'
    expect(o.alsovalid).to be_nil
  end

  it "can handle multiple valid options" do
    o = klass.new(:valid => 'yep', :alsovalid => 'yarp')
    expect(o.valid).to eq 'yep'
    expect(o.alsovalid).to eq 'yarp'
  end

  it "raises an error when given an unhandled option" do
    expect {
      klass.new(:valid => 'yep', :notvalid => 'newp')
    }.to raise_error(ArgumentError, /cannot handle option 'notvalid'/)
  end
end
