require 'faraday'

module PuppetForge
  module Connection
    # Wrap Faraday connection failures to include the host and optional proxy
    # in use for the failed connection.
    class ConnectionFailure < Faraday::Middleware
      def call(env)
        @app.call(env)
      rescue Faraday::ConnectionFailed => e
        baseurl = env[:url].dup
        baseurl.path = ''
        errmsg = "Unable to connect to #{baseurl.to_s}"
        if proxy = env[:request][:proxy]
          errmsg << " (using proxy #{proxy.uri.to_s})"
        end
        errmsg << ": #{e.message}"
        m = Faraday::ConnectionFailed.new(errmsg)
        m.set_backtrace(e.backtrace)
        raise m
      end
    end
  end
end

Faraday::Middleware.register_middleware(:connection_failure => lambda { PuppetForge::Connection::ConnectionFailure })
