require 'r10k/logging'

module R10K
  class Deployment
    class Config

      # Look for the r10k configuration file in standard locations.
      #
      # r10k.yaml is checked for in the following locations:
      #   - $PWD/r10k.yaml
      #   - /etc/puppetlabs/r10k/r10k.yaml
      #   - /etc/r10k.yaml
      class Loader

        def self.search(override = nil)
          new.search(override)
        end

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

        # Find the first valid config file.
        #
        # @param override [String, nil] An optional path that when is truthy
        #   will be preferred over all other files, to make it easy to
        #   optionally supply an explicit configuration file that will always
        #   be used when set.
        # @return [String, nil] The path to the first valid configfile, or nil
        #   if no file was found.
        def search(override = nil)
          return override if override

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
