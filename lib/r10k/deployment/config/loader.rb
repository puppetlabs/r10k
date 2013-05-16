
module R10K
class Deployment
class Config
class Loader
  # Search for a deployment configuration file (r10k.yaml) in all parent
  # directories and in /etc/r10k.yaml

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

    # Always check /etc/r10k.yaml
    @loadpath << '/etc/r10k.yaml'

    @loadpath
  end
end
end
end
end
