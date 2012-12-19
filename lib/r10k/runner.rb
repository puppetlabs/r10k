require 'r10k'
require 'r10k/root'
require 'r10k/synchro/git'
require 'yaml'

class R10K::Runner

  def self.instance
    @myself ||= self.new
  end

  # Load and store a config file, and set relevant options
  #
  # @param [String] configfile The path to the YAML config file
  def load(configfile)
    File.open(configfile) { |fh| @config = YAML.load(fh.read) }

    if @config[:cachedir]
      R10K::Synchro::Git.cache_root = @config[:cachedir]
    end
  rescue => e
    raise "Couldn't load #{configfile}: #{e}"
  end

  # Serve up the loaded config if it's already been loaded, otherwise try to
  # load a config in the current wd.
  def config
    self.load(File.join(Dir.getwd, "config.yaml")) unless @config

    @config
  end

  def run
    roots.each do |root|
      root.sync!

      pids = []
      root.modules.each do |mod|
        if (pid = Process.fork)
          pids << pid
        else
          mod.sync!
          exit!(0)
        end
      end

      pids.each do |pid|
        Process.waitpid(pid)
      end
    end
  end

  def cache_sources
    config[:sources].each_pair do |name, source|
      synchro = R10K::Synchro::Git.new(source)
      synchro.cache
    end
  end

  # Load up all module roots
  def roots
    environments = []

    environments << common_root

    config[:sources].each_pair do |name, source|
      synchro = R10K::Synchro::Git.new(source)
      synchro.cache
    end
  end

  def common_root
    @base ||= R10K::Root.new(
      self.config[:basedir],
      self.config[:installdir],
      self.config[:baserepo],
      'master')
  end
end
