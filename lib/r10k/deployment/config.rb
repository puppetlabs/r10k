require 'r10k/deployment'
require 'r10k/deployment/config/loader'

module R10K
class Deployment
class Config

  attr_accessor :configfile

  def initialize(configfile)
    @configfile = configfile

    load_config
  end

  # Perform a scan for key and check for both string and symbol keys
  def setting(key)
    keys = [key]
    case key
    when String
      keys << key.to_sym
    when Symbol
      keys << key.to_s
    end

    # Scan all possible keys to see if the config has a matching value
    keys.inject(nil) do |rv, k|
      v = @config[k]
      break v unless v.nil?
    end
  end

  # Load and store a config file, and set relevant options
  #
  # @param [String] configfile The path to the YAML config file
  def load_config
    if @configfile.nil?
      loader = R10K::Deployment::Config::Loader.new
      @configfile = loader.search
      if @configfile.nil?
        raise ConfigError, "No configuration file given, no config file found in parent directory, and no global config present"
      end
    end
    begin
      @config = YAML.load_file(@configfile)
      apply_config_settings
    rescue => e
      raise ConfigError, "Couldn't load config file: #{e.message}"
    end
  end

  private

  # Apply config settings to the relevant classes after a config has been loaded.
  #
  # @note this is hack. And gross. And terribad. I am sorry.
  def apply_config_settings
    cachedir = setting(:cachedir)
    if cachedir
      R10K::Git::Cache.cache_root = cachedir
    end
  end

  class ConfigError < StandardError
  end
end
end
end
