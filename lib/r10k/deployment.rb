require 'r10k'
require 'r10k/synchro/git'

class R10K::Deployment
  # Model a full installation of module directories and modules.

  def self.instance
    @myself ||= self.new
  end

  def initialize
    @configfile = File.join(Dir.getwd, "config.yaml")
    @update_cache = true
  end

  attr_accessor :configfile

  # Load up all module roots
  #
  # @return [Array<R10K::Root>]
  def environments
    environments = []

    setting(:sources).each_pair do |name, source|
      synchro = R10K::Synchro::Git.new(source)
      synchro.cache

      synchro.branches.each do |branch|
        environments << R10K::Root.new(
          "#{name}_#{branch}",
          setting(:envdir),
          source,
          branch,
        )
      end
    end

    environments
  end

  # Serve up the loaded config if it's already been loaded, otherwise try to
  # load a config in the current wd.
  def config
    unless @config
      begin
        loadconfig
      rescue => e
        raise "Couldn't load default config #{default_config}: #{e}"
      end
    end
    @config
  end

  # @return [Object] A top level key from the config hash
  def setting(key)
    self.config[key]
  end
  alias_method :[], :setting

  private

  # Apply config settings to the relevant classes after a config has been loaded.
  def apply_config_settings
    if @config[:cachedir]
      R10K::Synchro::Git.cache_root = @config[:cachedir]
    end
  end

  # Load and store a config file, and set relevant options
  #
  # @param [String] configfile The path to the YAML config file
  def loadconfig
    File.open(@configfile) { |fh| @config = YAML.load(fh.read) }
    apply_config_settings
    @config
  rescue => e
    raise "Couldn't load #{configfile}: #{e}"
  end

end
