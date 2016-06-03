require 'fileutils'

module R10K
  module Util

    # Mixin for purging stale directory contents.
    #
    # @abstract Classes using this mixin need to implement {#managed_directory} and
    #   {#desired_contents}
    module Purgeable

      # @!method logger
      #   @abstract Including classes must provide a logger method
      #   @return [Log4r::Logger]

      # @!method desired_contents
      #   @abstract Including classes must implement this method to list the
      #     expected filenames of managed_directories
      #   @return [Array<String>] The full paths to all the content this object is managing

      # @!method managed_directories
      #   @abstract Including classes must implement this method to return an array of
      #     paths that can be purged
      #   @return [Array<String>] The paths to the directories to be purged

      # @return [Array<String>] The present directory entries in `self.managed_directories`
      def current_contents
        dirs = self.managed_directories

        dirs.flat_map do |dir|
          glob_exp = File.join(dir, '*')

          Dir.glob(glob_exp)
        end
      end

      # @return [Array<String>] Directory contents that are expected but not present
      def pending_contents
        desired_contents - current_contents
      end

      # @return [Array<String>] Directory contents that are present but not expected
      def stale_contents
        current_contents - desired_contents
      end

      # Forcibly remove all unmanaged content in `self.managed_directories`
      def purge!
        if stale_contents.empty?
          logger.debug1 "No unmanaged contents in #{managed_directories.join(', ')}, nothing to purge"
        else
          stale_contents.each do |fpath|
            logger.info "Removing unmanaged path #{fpath}"
            FileUtils.rm_rf(fpath, :secure => true)
          end
        end
      end
    end
  end
end
