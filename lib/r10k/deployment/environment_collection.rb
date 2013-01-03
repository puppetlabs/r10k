require 'r10k'

class R10K::EnvironmentCollection

  attr_reader :update_cache

  def initialize(config, options = {:update_cache => false})
    @config       = config
    @environments = []

    @update_cache = options.delete(:update_cache)
    load_all
  end

  def current(basedir)
    basedir = File.expand_path(basedir)
    tracked_envs = @environments.select do |env|
      envdir = File.expand_path(env.basedir)
      envdir == basedir
    end
  end

  # List subdirectories that aren't associated with an env
  #
  # If a branch associated with an environment is deleted then the associated
  # branch ceases to be tracked. This method will scan a directory for
  # subdirectories and return any subdirectories that don't have an active
  # branch associated.
  #
  # @param [String] basedir The directory to scan
  #
  # @return [Array<String>] A list of filenames
  def stale(basedir)
    basedir = File.expand_path(basedir)

    all_dirs = Dir.glob("#{basedir}/*").map do |file|
      File.basename(file) if File.directory?(file)
    end.compact
    current_dirs = current(basedir).map(&:name)

    stale_dirs = all_dirs - current_dirs

    stale_dirs.map {|dir| File.join(basedir, dir)}
  end

  # @return [Array<R10K::Root>]
  def to_a
    @environments
  end

  private

  def load_all
    @config[:sources].each_pair do |repo_name, repo_config|
      synchro = R10K::Synchro::Git.new(repo_config['remote'])
      synchro.cache if @update_cache

      if repo_config['ref']
        @environments << R10K::Root.new(repo_config)
      else
        synchro.branches.each do |branch|
          @environments << R10K::Root.new(repo_config.merge({'ref' => branch}))
        end
      end
    end

    @environments
  end
end
