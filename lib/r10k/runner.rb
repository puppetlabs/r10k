require 'r10k'
require 'r10k/root'
require 'yaml'

class R10K::Runner; end

class << R10K::Runner

  def config(configfile)
    yaml = nil
    File.open(configfile) { |fh| yaml = YAML.load(fh.read) }

    yaml
  rescue => e
    raise "Couldn't load #{configfile}: #{e}"
  end

  def run
    c = config("../config.yaml")
    base = R10K::Root.new(c[:basedir], c[:installdir], c[:baserepo], 'master')
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
end
