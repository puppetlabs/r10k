require 'r10k/settings/definition'
require 'uri'

module R10K
  module Settings
    class URIDefinition < R10K::Settings::Definition
      def validate
        if @value
          begin
            URI.parse(@value)
          rescue URI::Error
            raise ArgumentError, "Setting #{@name} requires a URL but '#{@value}' could not be parsed as a URL"
          end
        end
        super
      end
    end
  end
end
