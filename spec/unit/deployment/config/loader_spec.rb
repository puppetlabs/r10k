require 'spec_helper'
require 'r10k/deployment/config/loader'

describe R10K::Deployment::Config::Loader do

  it "includes /etc/puppetlabs/r10k/r10k.yaml in the loadpath" do
    expect(subject.loadpath).to include("/etc/puppetlabs/r10k/r10k.yaml")
  end

  it "includes /etc/r10k.yaml in the loadpath" do
    expect(subject.loadpath).to include("/etc/r10k.yaml")
  end

  it "does not include /some/random/path/atomium/r10k.yaml in the loadpath" do
    expect(subject.loadpath).not_to include("/some/random/path/atomium/r10k.yaml")
  end

end
