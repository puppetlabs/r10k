require 'r10k/logging'

module R10K
  class Deployment
    class Config
      class Loader

        include R10K::Logging

        attr_reader :loadpath

        CONFIG_FILE = 'r10k.yaml'
        DEFAULT_LOCATION = File.join('/etc/puppetlabs/r10k', CONFIG_FILE)
        OLD_DEFAULT_LOCATION = File.join('/etc', CONFIG_FILE)

        # Search for a deployment configuration file (r10k.yaml) in several locations
        def initialize
          @loadpath = []
          populate_loadpath
        end

        # @return [String] The path to the first valid configfile
        def search

          # If both default files are present, issue a warning.
          if (File.file? DEFAULT_LOCATION) && (File.file? OLD_DEFAULT_LOCATION)
            logger.warn "Both #{DEFAULT_LOCATION} and #{OLD_DEFAULT_LOCATION} configuration files exist."
            logger.warn "#{DEFAULT_LOCATION} will be used."
          end

          path = @loadpath.find {|filename| File.file? filename}

          if path == OLD_DEFAULT_LOCATION
            logger.warn "The r10k configuration file at #{OLD_DEFAULT_LOCATION} is deprecated."
            logger.warn "Please move your r10k configuration to #{DEFAULT_LOCATION}."
          end

          path
        end

        private

        def populate_loadpath

          # Add the current directory for r10k.yaml
          @loadpath << File.join(Dir.getwd, CONFIG_FILE)

          # Add the AIO location for of r10k.yaml
          @loadpath << DEFAULT_LOCATION

          # Add the old default location last.
          @loadpath << OLD_DEFAULT_LOCATION

          @loadpath
        end
      end
    end
  end
end
