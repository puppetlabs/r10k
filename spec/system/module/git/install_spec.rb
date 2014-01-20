require 'system/spec_helper'

describe 'installing modules from git' do

  before(:all) { yum_install 'git' }
  after(:all) { shell %[yum -y remove git] }

  describe 'when no version is specified' do

    include_context 'system module installation'

    before(:all) do
      create_puppetfile(
        %[mod 'boolean', :git => 'git://github.com/adrienthebo/puppet-boolean']
      )
    end
    it "defaults to 'master'" do
      puppetfile_install

      shell %[git --git-dir=modules/boolean/.git rev-parse --abbrev-ref HEAD] do |results|
        expect(results.stdout).to match /master/
      end
    end
  end

  describe "with a ref" do

    include_context 'system module installation'

    before(:all) do
      create_puppetfile(
        %[mod 'boolean',
           :git => 'git://github.com/adrienthebo/puppet-boolean',
           :ref => '0.9.0'
        ]
      )
    end

    it "checks out the tag when the ref is a tag" do
      puppetfile_install

      shell %[git --git-dir=modules/boolean/.git rev-parse HEAD] do |results|
        expect(results.stdout).to match /3084373e8d181cf2fea5b4ade2690ba22872bd67/
      end
    end

    it "checks out the commit when the ref is a commit"
    it "checks out the branch when the ref is a branch"
  end

  describe "with a tag" do

    include_context 'system module installation'

    before(:all) do
      create_puppetfile(
        %[mod 'boolean',
           :git => 'git://github.com/adrienthebo/puppet-boolean',
           :tag => '0.9.0'
        ]
      )
    end

    it "checks out the tag" do
      puppetfile_install

      shell %[git --git-dir=modules/boolean/.git rev-parse HEAD] do |results|
        expect(results.stdout).to match /3084373e8d181cf2fea5b4ade2690ba22872bd67/
      end
    end
  end

  describe "with a commit" do

    include_context 'system module installation'

    before(:all) do
      create_puppetfile(
        %[mod 'boolean',
           :git => 'git://github.com/adrienthebo/puppet-boolean',
           :commit => 'd98ba4af3b4fd632fc7f2d652c4f9e142186dbd1'
        ]
      )
    end

    it "checks out the commit" do
      puppetfile_install

      shell %[git --git-dir=modules/boolean/.git rev-parse HEAD] do |results|
        expect(results.stdout).to match /d98ba4af3b4fd632fc7f2d652c4f9e142186dbd1/
      end
    end
  end

  describe "with a branch" do

    include_context 'system module installation'

    before(:all) do
      create_puppetfile(
        %[mod 'boolean',
           :git => 'git://github.com/adrienthebo/puppet-boolean',
           :branch => 'master'
        ]
      )
    end

    it "checks out the branch" do
      puppetfile_install

      shell %[git --git-dir=modules/boolean/.git rev-parse --abbrev-ref HEAD] do |results|
        expect(results.stdout).to match /master/
      end
    end
  end

end
