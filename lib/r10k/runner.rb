require 'r10k'
require 'r10k/root'
require 'yaml'

class R10K::Runner

  def self.instance
    @myself ||= self.new
  end

  def load(configfile)
    File.open(configfile) { |fh| @config = YAML.load(fh.read) }
  rescue => e
    raise "Couldn't load #{configfile}: #{e}"
  end

  # Serve up the loaded config if it's already been loaded, otherwise try to
  # load a config in the current wd.
  def config
    @config ||= self.load(File.join(Dir.getwd, "config.yaml"))
  end

  def run
    base.sync!

    threads = []
    base.modules.each do |mod|
      threads << Thread.new do
        mod.sync!
      end
    end

    threads.each do |thr|
      thr.join
    end
  end

  # Load up all module roots
  def roots
    environments = []

    environments << common_root
  end

  def common_root
    @base ||= R10K::Root.new(
      config[:basedir],
      config[:installdir],
      config[:baserepo],
      'master')
  end
end
