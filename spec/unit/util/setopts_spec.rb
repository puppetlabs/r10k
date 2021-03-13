require 'spec_helper'
require 'r10k/util/setopts'

describe R10K::Util::Setopts do
  let(:klass) do
    Class.new do
      include R10K::Util::Setopts

      attr_reader :valid, :alsovalid, :truthyvalid

      def initialize(opts = {})
        setopts(opts, {
          :valid => :self,
          :duplicate => :valid,
          :alsovalid => :self,
          :truthyvalid => true,
          :validalias => :valid,
          :ignoreme => nil
        })
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

  it "can handle options marked with TrueClass" do
    o = klass.new(:truthyvalid => 'so truthy')
    expect(o.truthyvalid).to eq 'so truthy'
  end

  it "can handle aliases marked with :self" do
    o = klass.new(:validalias => 'yuuup')
    expect(o.valid).to eq 'yuuup'
  end


  it "raises an error when given an unhandled option" do
    expect {
      klass.new(:valid => 'yep', :notvalid => 'newp')
    }.to raise_error(ArgumentError, /cannot handle option 'notvalid'/)
  end

  it "warns when given an unhandled option and raise_on_unhandled=false" do
    test = Class.new { include R10K::Util::Setopts }.new
    allow(test).to receive(:logger).and_return(spy)

    test.send(:setopts, {valid: :value, invalid: :value},
                        {valid: :self},
                        raise_on_unhandled: false)

    expect(test.logger).to have_received(:warn).with(%r{cannot handle option 'invalid'})
  end

  it "ignores values that are marked as unhandled" do
    klass.new(:ignoreme => "IGNORE ME!")
  end

  it "warns when given conflicting options" do
    test = Class.new { include R10K::Util::Setopts }.new
    allow(test).to receive(:logger).and_return(spy)

    test.send(:setopts, {valid: :one, duplicate: :two},
                        {valid: :arg, duplicate: :arg})

    expect(test.logger).to have_received(:warn).with(%r{valid.*duplicate.*conflict.*not both})
  end
end
