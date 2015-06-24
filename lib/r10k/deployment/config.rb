require 'r10k/deployment'
require 'r10k/settings/loader'
require 'r10k/util/symbolize_keys'
require 'r10k/errors'
require 'yaml'

module R10K
class Deployment
class Config

  include R10K::Logging

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
    loader = R10K::Settings::Loader.new
    @config = loader.read(@configfile)
    initializer = R10K::Initializers::GlobalInitializer.new(@config)
    initializer.call
  end

  class ConfigError < R10K::Error
  end
end
end
end
