require 'r10k'
require 'r10k/root'
require 'r10k/synchro/git'
require 'yaml'

class R10K::Config

  def self.instance
    @myself ||= self.new
  end

  # Load and store a config file, and set relevant options
  #
  # @param [String] configfile The path to the YAML config file
  def load(configfile)
    @configfile = configfile
    File.open(configfile) { |fh| @config = YAML.load(fh.read) }
    apply_config_settings
    @config
  rescue => e
    raise "Couldn't load #{configfile}: #{e}"
  end

  # Serve up the loaded config if it's already been loaded, otherwise try to
  # load a config in the current wd.
  def config
    unless @config
      default_config = File.join(Dir.getwd, "config.yaml")
      begin
        self.load(default_config)
      rescue => e
        raise "No configuration loaded and couldn't load #{default_config}"
      end
    end
    @config
  end

  def sources

  end

  private

  # Apply config settings to the relevant classes after a config has been loaded.
  def apply_config_settings
    if @config[:cachedir]
      R10K::Synchro::Git.cache_root = @config[:cachedir]
    end
  end
end
