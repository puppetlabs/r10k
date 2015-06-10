require 'shared/puppet_forge/v3/module_release'

describe PuppetForge::V3::ModuleRelease do

  subject { described_class.new('username-modulename', '3.1.4') }

  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:conn) do
    Faraday.new do |builder|
      builder.response(:raise_error)
      builder.adapter :test, faraday_stubs
    end
  end

  before do
    subject.conn = conn
  end

  it "creates a slug from the full_name and version" do
    expect(subject.slug).to eq 'username-modulename-3.1.4'
  end


  describe '#data' do
    it 'returns the body of the response' do
      faraday_stubs.get('/v3/releases/username-modulename-3.1.4') { [200, {}, {'metadata' => 'yep'}] }
      expect(subject.data).to eq('metadata' => 'yep')
    end

    it 'raises an error if the module release does not exist' do
      faraday_stubs.get('/v3/releases/username-modulename-3.1.4') { [404, {}, {'metadata' => 'yep'}] }
      expect {
        subject.data
      }.to raise_error(PuppetForge::ModuleReleaseNotFound, /The module release username-modulename-3\.1\.4 does not exist/)
    end
  end

  describe '#download' do
    it 'downloads the file to the provided path' do
      faraday_stubs.get('/v3/files/username-modulename-3.1.4.tar.gz') { [200, {}, "I'm a file!"] }

      path = Pathname.new('/some/path')
      io   = instance_double('IO')

      expect(path).to receive(:open).with('wb').and_yield io
      expect(io).to receive(:write).with("I'm a file!")

      subject.download(path)
    end

    it 'raises an error if the module release does not exist' do
      faraday_stubs.get('/v3/files/username-modulename-3.1.4.tar.gz') { [404, {}, 'not found'] }
      expect {
        subject.download(Pathname.new('/some/path'))
      }.to raise_error(PuppetForge::ModuleReleaseNotFound, /The module release username-modulename-3\.1\.4 does not exist/)
    end
  end

  describe '#verify' do
    let(:digest) { instance_double('Digest::MD5') }

    let(:path) { Pathname.new('/some/path') }

    it "returns without error when the checksum matches" do
      expect(Digest::MD5).to receive(:file).with(path).and_return(digest)
      expect(digest).to receive(:hexdigest).and_return('823fe0a11fc0ef23a5853e2791880c9b')
      expect(subject).to receive(:data).and_return('file_md5' => '823fe0a11fc0ef23a5853e2791880c9b')

      subject.verify(path)
    end

    it "raises an error when the checksum doesn't match" do
      expect(Digest::MD5).to receive(:file).with(path).and_return(digest)
      expect(digest).to receive(:hexdigest).and_return('00000000000000000000000000000000')
      expect(subject).to receive(:data).and_return('file_md5' => '823fe0a11fc0ef23a5853e2791880c9b')

      expect {
        subject.verify(path)
      }.to raise_error(PuppetForge::V3::ModuleRelease::ChecksumMismatch, 'Expected /some/path checksum to be 823fe0a11fc0ef23a5853e2791880c9b, got 00000000000000000000000000000000')
    end
  end
end
