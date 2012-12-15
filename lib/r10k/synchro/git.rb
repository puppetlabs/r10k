require 'r10k'

module R10K::Synchro; end

class R10K::Synchro::Git
  attr_reader :source

  def initialize(source)
    @source = source
  end

  # loldox
  #
  # @param [String] path The destination path for the files
  # @param [String] branch The git branch to instantiate at the destination path
  def sync(path, branch)

    if File.directory?(File.join(path, '.git'))
      fetch(path)
      reset(path, branch)
    else
      clone(path, branch)
    end
  end

  private

  def clone(path, branch)
    puts("git clone #{source} #{path}")
    system("git clone #{source} #{path}")
    reset(path, branch)
  end

  def fetch(path)
    system("git --git-dir #{path}/.git fetch")
  end

  def reset(path, branch)
    puts("git --work-tree #{path} --git-dir #{path}/.git reset --hard #{branch}")
    system("git --work-tree #{path} --git-dir #{path}/.git reset --hard #{branch}")
  end
end
