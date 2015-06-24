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
    if @configfile.nil?
      loader = R10K::Settings::Loader.new
      @configfile = loader.search
      if @configfile.nil?
        raise ConfigError, "No configuration file given, no config file found in current directory, and no global config present"
      end
    end
    begin
      @config = ::YAML.load_file(@configfile)
      apply_config_settings
    rescue => e
      raise ConfigError, "Couldn't load config file: #{e.message}"
    end
  end

  private

  def with_setting(key, &block)
    value = setting(key)
    block.call(value) unless value.nil?
  end

  # Apply global configuration settings.
  def apply_config_settings
    with_setting(:purgedirs) do |purgedirs|
      logger.warn("The purgedirs key in r10k.yaml is deprecated. It is currently ignored.")
    end

    with_setting(:cachedir) do |cachedir|
      R10K::Git::Cache.settings[:cache_root] = cachedir
    end

    with_setting(:forge) do |forge_settings|
      R10K::Util::SymbolizeKeys.symbolize_keys!(forge_settings)
      proxy = forge_settings[:proxy]
      if proxy
        R10K::Forge::ModuleRelease.settings[:proxy] = proxy
      end

      baseurl = forge_settings[:baseurl]
      if baseurl
        R10K::Forge::ModuleRelease.settings[:baseurl] = baseurl
      end
    end

    with_setting(:git) do |git_settings|
      R10K::Util::SymbolizeKeys.symbolize_keys!(git_settings)
      provider = git_settings[:provider]
      if provider
        R10K::Git.provider = provider.to_sym
      end

      if git_settings[:private_key]
        R10K::Git.settings[:private_key] = git_settings[:private_key]
      end

      if git_settings[:username]
        R10K::Git.settings[:username] = git_settings[:username]
      end
    end
  end

  class ConfigError < R10K::Error
  end
end
end
end
