require 'shared/puppet_forge/tar'

describe PuppetForge::Tar do

  it "returns an instance of minitar" do
    expect(described_class.instance).to be_a_kind_of PuppetForge::Tar::Mini
  end

end
