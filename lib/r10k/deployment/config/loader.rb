require 'r10k/logging'

module R10K
  class Deployment
    class Config
      class Loader

        include R10K::Logging

        attr_reader :loadpath

        DEFAULT_LOCATION = '/etc/puppetlabs/r10k/r10k.yaml'
        OLD_DEFAULT_LOCATION = '/etc/r10k.yaml'

        # Search for a deployment configuration file (r10k.yaml) in
        # /etc/puppetlabs/r10k/r10k.yaml
        # /etc/r10k.yaml
        # and current directory
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

          first = @loadpath.find {|filename| File.file? filename}
        end

        private

        def populate_loadpath

          # Scan all parent directories for r10k
          dir_components = Dir.getwd.split(File::SEPARATOR)

          dir_components.each_with_index do |dirname, index|
            full_path = [''] # Shim case for root directory
            full_path << dir_components[0...index]
            full_path << dirname << 'r10k.yaml'

            @loadpath << File.join(full_path)
          end

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
