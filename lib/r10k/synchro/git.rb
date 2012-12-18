require 'r10k'
require 'cocaine'
require 'logger'

Cocaine::CommandLine.logger = ::Logger.new(STDOUT)

module R10K::Synchro; end

class R10K::Synchro::Git
  attr_reader :source

  def initialize(source)
    @source = source
  end

  # loldox
  #
  # @param [String] path The destination path for the files
  # @param [String] ref The git ref to instantiate at the destination path
  def sync(path, ref)

    path = File.expand_path(path)

    if File.directory?(File.join(path, '.git'))
      fetch(path)
      reset(path, ref)
    else
      clone(path, ref)
    end
  end

  private

  def clone(path, ref)
    git "clone #{source} #{path}"
    reset(path, ref)
  end

  def fetch(path)
    git "fetch", path
  end

  def reset(path, ref)
    # THIS IS A TOTAL HACK.
    begin
      commit = git "rev-parse #{ref}^{commit}", path
    rescue Cocaine::ExitStatusError
      commit = "origin/#{ref}"
    end
    git "reset --hard #{commit}", path
  end

  def git(str, path = nil)
    git_str = path ? "git --work-tree #{path} --git-dir #{path}/.git" : "git"
    cmd = Cocaine::CommandLine.new("#{git_str} #{str}")
    cmd.run
  end
end
