require 'system/spec_helper'

describe 'installing modules from the forge' do

  describe 'when no version is specified' do

    include_context 'system module installation'

    before(:all) do
      shell %[echo 'mod "adrien/boolean"' > ./Puppetfile]
      shell %[r10k puppetfile install]
    end

    describe file('modules/boolean/metadata.json') do
      its(:content) { should match /adrien-boolean/ }
      its(:content) { should match /version.*1\.0\.1/ }
    end
  end

  describe 'when a specific version is specified' do

    include_context 'system module installation'

    before(:all) do
      shell %[echo 'mod "adrien/boolean", "0.9.0"' > ./Puppetfile]
      shell %[r10k puppetfile install]
    end

    describe file('modules/boolean/metadata.json') do
      its(:content) { should match /adrien-boolean/ }
      its(:content) { should match /version.*0\.9\.0/ }
    end
  end

  describe 'when the latest version is requested' do

    include_context 'system module installation'

    before(:all) do
      shell %[echo 'mod "adrien/boolean", "0.9.0"' > ./Puppetfile]
      shell %[r10k puppetfile install]
      shell %[echo 'mod "adrien/boolean", :latest' > ./Puppetfile]
    end

    it 'upgrades to the latest version' do
      shell %[r10k puppetfile install]

      expect(file('modules/boolean/metadata.json').content).to match /version.*1\.0\.1/
    end
  end
end
