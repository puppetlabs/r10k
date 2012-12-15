require 'r10k'
require 'r10k/root'
require 'r10k/librarian'
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
    base = R10K::Root.new(c[:baserepo], c[:basedir], 'master')
    base.sync!

    l = R10K::Librarian.new("base/Puppetfile")

    modules     = l.load
    git_modules = modules.select { |mod| mod[1].is_a? Hash }

    git_modules.each do |mod|
      name, hash = mod[0], mod[1]

      modmaker = R10K::Synchro::Git.new(hash[:git])
      modmaker.sync("modules/#{name}", (hash[:ref] || 'master'))
    end
  end
end
