require 'spec_helper'
require 'r10k/util/downloader'

describe R10K::Util::Downloader do

  subject(:downloader) do
    subj = Object.new
    subj.extend(R10K::Util::Downloader)
    subj.singleton_class.class_eval { public :download }
    subj.singleton_class.class_eval { public :http_get }
    subj.singleton_class.class_eval { public :file_digest }
    subj
  end

  let(:tmpdir) { Dir.mktmpdir }
  after(:each) { FileUtils.remove_entry_secure(tmpdir) }

  describe 'http_get' do
    let(:src_url) { 'https://example.com' }
    let(:dst_file) { File.join(tmpdir, 'test.out') }
    let(:tarball_uri) { URI('http://tarball.example.com/tarball.tar.gz') }
    let(:redirect_uri) { URI('http://redirect.example.com/redirect') }
    let(:proxy_uri) { URI('http://user:password@proxy.example.com') }

    it 'downloads a simple file' do
      mock_session = instance_double('Net::HTTP', active?: true)
      tarball_response = instance_double('Net::HTTPSuccess')

      expect(Net::HTTP).to receive(:new).with(tarball_uri.host, any_args).and_return(mock_session)
      expect(Net::HTTPSuccess).to receive(:===).with(tarball_response).and_return(true)

      expect(mock_session).to receive(:request_get).and_yield(tarball_response)
      expect(mock_session).to receive(:start).once
      expect(mock_session).to receive(:finish).once

      expect { |b| downloader.http_get(tarball_uri, &b) }.to yield_with_args(tarball_response)
    end

    it 'follows redirects' do
      mock_session_1 = instance_double('Net::HTTP', active?: false)
      mock_session_2 = instance_double('Net::HTTP', active?: true)
      redirect_response = instance_double('Net::HTTPRedirection')
      tarball_response = instance_double('Net::HTTPSuccess')

      expect(Net::HTTP).to receive(:new).with(redirect_uri.host, any_args).and_return(mock_session_1).once
      expect(Net::HTTP).to receive(:new).with(tarball_uri.host, any_args).and_return(mock_session_2).once
      expect(Net::HTTPRedirection).to receive(:===).with(redirect_response).and_return(true)
      expect(Net::HTTPSuccess).to receive(:===).with(tarball_response).and_return(true)
      allow(Net::HTTPRedirection).to receive(:===).and_call_original

      expect(mock_session_1).to receive(:request_get).and_yield(redirect_response)
      expect(mock_session_2).to receive(:request_get).and_yield(tarball_response)

      # The redirect response should be queried for the redirect location
      expect(redirect_response).to receive(:[]).with('location').and_return(tarball_uri.to_s)

      # Both sessions should start and finish cleanly
      expect(mock_session_1).to receive(:start).once
      expect(mock_session_1).to receive(:finish).once
      expect(mock_session_2).to receive(:start).once
      expect(mock_session_2).to receive(:finish).once

      expect { |b| downloader.http_get(redirect_uri, &b) }.to yield_with_args(tarball_response)
    end

    it 'can use a proxy' do
      mock_session = instance_double('Net::HTTP', active?: true)

      expect(Net::HTTP).to receive(:new)
                       .with(tarball_uri.host,
                             tarball_uri.port,
                             proxy_uri.host,
                             proxy_uri.port,
                             proxy_uri.user,
                             proxy_uri.password,
                             any_args)
                       .and_return(mock_session)

      expect(mock_session).to receive(:request_get).and_return(:not_yielded)
      expect(mock_session).to receive(:start).once
      expect(mock_session).to receive(:finish).once

      downloader.http_get(tarball_uri, proxy: proxy_uri)
    end
  end

  describe 'checksums' do
    let(:fixture_checksum) { '0bcea17aa0c5e868c18f0fa042feda770e47c1a4223229f82116ccb3ca33c6e3' }
    let(:fixture_tarball) do
      File.expand_path('spec/fixtures/integration/git/puppet-boolean-bare.tar', PROJECT_ROOT)
    end

    it 'checksums files' do
      expect(downloader.file_digest(fixture_tarball)).to eql(fixture_checksum)
    end
  end
end

