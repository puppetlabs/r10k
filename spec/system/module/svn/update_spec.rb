require 'system/spec_helper'

describe 'updating modules from SVN' do

  extend SystemProvisioning::EL

  before(:all) { yum_install 'subversion' }
  after(:all) { shell %[yum -y remove subversion] }


  it "reinstalls the module when the installed module isn't an svn repo"
  it "reinstalls the module when the svn url doesn't match the installed module"

  describe 'updating to a specific revision' do

    include_context 'system module installation'

    before(:all) do
      shell %[echo "mod 'gitolite', :svn => 'https://github.com/nvalentine-puppetlabs/puppet-gitolite/trunk', :rev => '10'" > ./Puppetfile]
      shell %[r10k puppetfile install]
      shell %[echo "mod 'gitolite', :svn => 'https://github.com/nvalentine-puppetlabs/puppet-gitolite/trunk', :rev => '20'" > ./Puppetfile]
    end

    it "installs the module successfully" do
      shell %[r10k puppetfile install] do |sh|
        expect(sh.exit_code).to eq 0
      end
    end

    it "checks out the specific revision" do
      expect(command('cd modules/gitolite; svn info')).to return_stdout /Revision: 20/
    end
  end

  describe 'when the installed revision is newer than the requested version' do
    it 'downgrades the module'
  end
end
