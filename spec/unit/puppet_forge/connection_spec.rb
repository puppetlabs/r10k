require 'shared/puppet_forge/connection'

describe PuppetForge::Connection do

  let(:extended) { Object.new.extend(described_class) }

  describe 'creating a new connection' do

    let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }

    subject { extended.make_connection('https://some.site/url', [:test, faraday_stubs]) }

    it 'parses response bodies with a JSON content-type into a hash' do
      faraday_stubs.get('/json') { [200, {'Content-Type' => 'application/json'}, '{"hello": "world"}'] }
      expect(subject.get('/json').body).to eq('hello' => 'world')
    end

    it 'returns the response body as-is when the content-type is not JSON' do
      faraday_stubs.get('/binary') { [200, {'Content-Type' => 'application/octet-stream'}, 'I am a big bucket of binary data'] }
      expect(subject.get('/binary').body).to eq('I am a big bucket of binary data')
    end

    it 'raises errors when the request has an error status code' do
      faraday_stubs.get('/error') { [503, {}, "The server caught fire and cannot service your request right now"] }

      expect {
        subject.get('/error')
      }.to raise_error(Faraday::ClientError, "the server responded with status 503")
    end
  end
end
