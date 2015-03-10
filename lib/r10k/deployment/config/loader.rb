
module R10K
  class Deployment
    class Config
      class Loader

        attr_reader :loadpath

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
          @loadpath << '/etc/puppetlabs/r10k/r10k.yaml'

          # Add the old default location.
          @loadpath << '/etc/r10k.yaml'

          @loadpath
        end
      end
    end
  end
end
