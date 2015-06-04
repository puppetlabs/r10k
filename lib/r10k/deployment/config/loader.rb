require 'r10k/logging'

module R10K
  class Deployment
    class Config
      class Loader

        include R10K::Logging

        attr_reader :loadpath

        CONFIG_FILE = 'r10k.yaml'
        DEFAULT_LOCATION = File.join('/etc/puppetlabs/r10k', CONFIG_FILE)

        # Search for a deployment configuration file (r10k.yaml) in several locations
        def initialize
          @loadpath = []
          populate_loadpath
        end

        # @return [String] The path to the first valid configfile
        def search
          first = @loadpath.find {|filename| File.file? filename}
        end

        private

        def populate_loadpath

          # Add the current directory for r10k.yaml
          @loadpath << File.join(Dir.getwd, CONFIG_FILE)

          # Add the AIO location for of r10k.yaml
          @loadpath << DEFAULT_LOCATION

          @loadpath
        end
      end
    end
  end
end
