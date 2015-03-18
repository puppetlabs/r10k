require 'spec_helper'

describe R10K::Deployment::Config do

  describe "reading settings" do
    # Try all permutations of string/symbol values as arguments to #setting and
    # values in the config file
    x = [:key, "key"]
    matrix = x.product(x)

    matrix.each do |(searchvalue, configvalue)|
      it "treats #{searchvalue.inspect}:#{searchvalue.class} and #{configvalue.inspect}:#{configvalue.class} as equivalent" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return(configvalue => 'some/cache')
        subject = described_class.new('foo/bar')
        expect(subject.setting(searchvalue)).to eq 'some/cache'
      end
    end
  end
end
