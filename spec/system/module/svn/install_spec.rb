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

  describe 'when a revision is specified' do
    before(:all) do
      shell %[rm -r modules]
      shell %[echo "mod 'gitolite', :svn => 'https://github.com/nvalentine-puppetlabs/puppet-gitolite/trunk', :rev => '10'" > ./Puppetfile]
    end

    it "installs the module successfully" do
      shell %[r10k puppetfile install] do |sh|
        expect(sh.exit_code).to eq 0
      end
    end

    it "creates the svn module" do
      expect(file('modules/gitolite/.svn')).to be_directory
    end

    it "checks out the specific revision" do
      expect(command('cd modules/gitolite; svn info')).to return_stdout /Revision: 10/
    end

    after(:all) do
      shell %[rm -r modules]
    end
  end

  describe 'updating to a specific revision' do
    before(:all) do
      shell %[rm -r modules]
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

    after(:all) do
      shell %[rm -r modules]
    end
  end
end
