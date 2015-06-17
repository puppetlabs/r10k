require 'spec_helper'
require 'shared/puppet_forge/connection/connection_failure'

describe PuppetForge::Connection::ConnectionFailure do

  subject do
    Faraday.new('https://my-site.url/some-path') do |builder|
      builder.use(:connection_failure)

      builder.adapter :test do |stub|
        stub.get('/connectfail') { raise Faraday::ConnectionFailed.new(SocketError.new("getaddrinfo: Name or service not known"), :hi) }
      end
    end
  end

  it "includes the base URL in the error message" do
    expect {
      subject.get('/connectfail')
    }.to raise_error(Faraday::ConnectionFailed, "Unable to connect to https://my-site.url: getaddrinfo: Name or service not known")
  end

  it "includes the proxy host in the error message when set" do
    subject.proxy('https://some-unreachable.proxy:3128')
    expect {
      subject.get('/connectfail')
    }.to raise_error(Faraday::ConnectionFailed, "Unable to connect to https://my-site.url (using proxy https://some-unreachable.proxy:3128): getaddrinfo: Name or service not known")
  end
end
