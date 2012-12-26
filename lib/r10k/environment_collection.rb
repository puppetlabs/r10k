require 'r10k'

class R10K::EnvironmentCollection

  attr_reader :update_cache

  def initialize(config, options = {:update_cache => true})
    @config       = config
    @environments = []

    @update_cache = options.delete(:update_cache)

    load_all
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
  def untracked_environments(basedir)
    raise NotImplementedError
  end

  # @return [Array<R10K::Root>]
  def to_a
    load_all
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
