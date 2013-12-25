require 'spec_helper'
require 'r10k/deployment/source'

describe R10K::Deployment::Source do
  let(:name) { 'do_not_name_a_branch_this' }
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:basedir)    { '/tmp' }

  describe 'environments', :integration => true do
    it 'uses the name as a prefix when told' do
      subject = described_class.new(name, remote, basedir, true)
      subject.fetch_remote()
      subject.environments.length.should  > 0
      subject.environments.first.dirname.should start_with name
    end

    it 'avoids using the name as a prefix when told' do
      subject = described_class.new(name, remote, basedir, false)
      subject.fetch_remote()
      subject.environments.length.should  > 0
      subject.environments.first.dirname.should_not start_with name
    end
  end
end
