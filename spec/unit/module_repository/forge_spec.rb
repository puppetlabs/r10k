require 'spec_helper'

require 'r10k/module_repository/forge'

describe R10K::ModuleRepository::Forge do

  it "uses the official forge by default" do
    forge = described_class.new
    expect(forge.forge).to eq 'forge.puppetlabs.com'
  end

  it "can use a private forge" do
    forge = described_class.new('forge.example.local')
    expect(forge.forge).to eq 'forge.example.local'
  end

  it "can fetch all versions of a given module"
  it "can fetch the latest version of a given module"
end
