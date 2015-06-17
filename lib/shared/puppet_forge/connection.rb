require 'shared/puppet_forge/version'
require 'shared/puppet_forge/connection/connection_failure'

require 'faraday'
require 'faraday_middleware'

module PuppetForge
  # Provide a common mixin for adding a HTTP connection to classes.
  #
  # This module provides a common method for creating HTTP connections as well
  # as reusing a single connection object between multiple classes. Including
  # classes can invoke #conn to get a reasonably configured HTTP connection.
  # Connection objects can be passed with the #conn= method.
  #
  # @example
  #   class HTTPThing
  #     include PuppetForge::Connection
  #   end
  #   thing = HTTPThing.new
  #   thing.conn = thing.make_connection('https://non-standard-forge.site')
  #
  # @api private
  module Connection

    attr_writer :conn

    USER_AGENT = "PuppetForge/#{PuppetForge::VERSION} Faraday/#{Faraday::VERSION} Ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"

    def self.authorization=(token)
      @authorization = token
    end

    def self.authorization
      @authorization
    end

    # @return [Faraday::Connection] An existing Faraday connection if one was
    #   already set, otherwise a new Faraday connection.
    def conn
      @conn ||= make_connection('https://forgeapi.puppetlabs.com')
    end

    # Generate a new Faraday connection for the given URL.
    #
    # @param url [String] the base URL for this connection
    # @return [Faraday::Connection]
    def make_connection(url, adapter_args = nil)
      adapter_args ||= [Faraday.default_adapter]
      options = { :headers => { :user_agent => USER_AGENT }}

      if token = PuppetForge::Connection.authorization
        options[:headers][:authorization] = token
      end

      Faraday.new(url, options) do |builder|
        builder.response(:json, :content_type => /\bjson$/)
        builder.response(:raise_error)
        builder.use(:connection_failure)

        builder.adapter(*adapter_args)
      end
    end
  end
end
