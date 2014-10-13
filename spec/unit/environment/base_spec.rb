require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Base do

  subject(:environment) { described_class.new('envname', '/some/imaginary/path', 'env_name', {}) }

  it "can return the fully qualified path" do
    expect(environment.path).to eq(Pathname.new('/some/imaginary/path/env_name'))
  end

  it "raises an exception when #sync is called" do
    expect { environment.sync }.to raise_error(NotImplementedError)
  end
end
