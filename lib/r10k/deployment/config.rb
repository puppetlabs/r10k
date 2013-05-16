require 'r10k/deployment'
require 'r10k/config/loader'

module R10K
class Deployment
class Config

  attr_accessor :configfile

  def initialize(configfile)
    @configfile = configfile

    load_config
  end

  def setting(key)
    @config[key]
  end

  # Load and store a config file, and set relevant options
  #
  # @param [String] configfile The path to the YAML config file
  def load_config
    if @configfile.nil?
      loader = R10K::Config::Loader.new
      @configfile = loader.search
    end
    @config = YAML.load_file(@configfile)
    apply_config_settings
    @config
  end

  private

  # Apply config settings to the relevant classes after a config has been loaded.
  #
  # @note this is hack. And gross. And terribad. I am sorry.
  def apply_config_settings
    if @config[:cachedir]
      R10K::Git::Cache.cache_root = @config[:cachedir]
    end
  end
end
end
end
