require 'r10k/logging'
require 'r10k/util/purgeable'

module R10K
  module Util
    class Cleaner

      include R10K::Logging
      include R10K::Util::Purgeable

      attr_reader :managed_directories, :desired_contents, :purge_exclusions

      def initialize(managed_directories, desired_contents, purge_exclusions = [])
        @managed_directories = managed_directories
        @desired_contents    = desired_contents
        @purge_exclusions    = purge_exclusions
      end

    end
  end
end
