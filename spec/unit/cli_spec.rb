require 'spec_helper'

RSpec.describe 'basic cli sanity check' do
  it 'can load the R10K::CLI namespace' do
    expect {
      require 'r10k/cli'
    }.not_to raise_exception
  end
end
