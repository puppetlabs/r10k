require 'r10k/git/cache'
require 'r10k/deployment/environment'
require 'r10k/util/purgeable'

module R10K
  class Deployment

    # Represents a directory containing environments
    # @api private
    class Basedir

      def initialize(path,deployment)
        @path       = path
        @deployment = deployment
      end

      include R10K::Util::Purgeable

      # Return the path of the basedir
      # @note This implements a required method for the Purgeable mixin
      # @return [String]
      def managed_directory
        @path
      end

      # List all environments that should exist in this basedir
      # @note This implements a required method for the Purgeable mixin
      # @return [Array<String>]
      def desired_contents
        @deployment.sources.inject([])do |list, source|
          if source.managed_directory == @path
            list += source.desired_contents
          end
          list
        end
      end
    end
  end
end
