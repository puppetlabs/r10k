require 'r10k'
require 'r10k/config'

class R10K::Deployment
  # Model a full installation of module directories and modules.

  def initialize(config)
    @config = config
  end

  # Load up all module roots
  #
  # @return [Array<R10K::Root>]
  def environments
    environments = []

    @config.setting(:sources).each_pair do |name, source|
      synchro = R10K::Synchro::Git.new(source)
      synchro.cache

      synchro.branches.each do |branch|
        environments << R10K::Root.new(
          "#{name}_#{branch}",
          @config.setting(:envdir),
          source,
          branch,
        )
      end
    end

    environments
  end
end
