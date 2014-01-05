require 'system/spec_helper'

describe 'installing modules from SVN' do

  extend SystemProvisioning::EL

  before(:all) { yum_install 'subversion' }
  after(:all) { shell %[yum -y remove subversion] }

  describe 'when no version is specified' do

    before(:all) do
      shell %[rm -r modules]
      shell %[echo "mod 'gitolite', :svn => 'https://github.com/nvalentine-puppetlabs/puppet-gitolite/trunk'" > ./Puppetfile]
    end

    it "installs the module successfully" do
      shell %[r10k puppetfile install] do |sh|
        expect(sh.exit_code).to eq 0
      end
    end

    it "creates the svn module" do
      expect(file('modules/gitolite/.svn')).to be_directory
    end

    after(:all) do
      shell %[rm -r modules]
    end
  end
end
