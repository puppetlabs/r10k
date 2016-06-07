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
      def current_contents(recurse)
        dirs = self.managed_directories

        dirs.flat_map do |dir|
          if recurse
            glob_exp = File.join(dir, '**', '{*,.*}')
          else
            glob_exp = File.join(dir, '*')
          end

          Dir.glob(glob_exp)
        end
      end

      # @return [Array<String>] Directory contents that are expected but not present
      def pending_contents(recurse)
        desired_contents - current_contents(recurse)
      end

      # @return [Array<String>] Directory contents that are present but not expected
      def stale_contents(recurse, whitelist)
        (current_contents(recurse) - desired_contents).reject do |item|
          whitelist.any? { |whitelist_item| /^#{Regexp.escape(whitelist_item)}/ =~ item }
        end
      end

      # Forcibly remove all unmanaged content in `self.managed_directories`
      def purge!(opts={})
        whitelist = opts[:whitelist] || []
        recurse = opts[:recurse] || false

        stale = stale_contents(recurse, whitelist)

        if stale.empty?
          logger.debug1 "No unmanaged contents in #{managed_directories.join(', ')}, nothing to purge"
        else
          stale.each do |fpath|
            begin
              FileUtils.rm_r(fpath, :secure => true)
              logger.info "Removed unmanaged path: #{fpath}"
            rescue Errno::ENOENT
              # Don't log on ENOENT since we may encounter that from recursively deleting
              # this item's parent earlier in the purge.
            rescue
              logger.debug1 "Unable to remove unmanaged path: #{fpath}"
            end
          end
        end
      end
    end
  end
end
