require 'shared/puppet_forge/v3/module'

describe PuppetForge::V3::Module do
  subject { described_class.new('authorname-modulename') }

  describe '#release' do
    it 'creates a release object for the module with the given version' do
      release = subject.release('3.1.4')
      expect(release.slug).to eq 'authorname-modulename-3.1.4'
    end

    it 'passes along the module connection object' do
      conn = Object.new
      subject.conn = conn
      release = subject.release('3.1.4')
      expect(release.conn).to eq conn
    end
  end
end
