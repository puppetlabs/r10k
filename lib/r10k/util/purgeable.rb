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
            glob_exp = File.join(dir, '**', '{*,.[^.]*}')
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
      def stale_contents(recurse, exclusions, whitelist)
        (current_contents(recurse) - desired_contents).reject do |item|
          if exclusion_match = exclusions.find { |ex_item| File.fnmatch?(ex_item, item, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
            logger.debug2 "Not purging #{item} due to internal exclusion match: #{exclusion_match}"
          elsif whitelist_match = whitelist.find { |wl_item| File.fnmatch?(wl_item, item, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
            logger.debug "Not purging #{item} due to whitelist match: #{whitelist_match}"
          end

          !!exclusion_match || !!whitelist_match
        end
      end

      # Forcibly remove all unmanaged content in `self.managed_directories`
      def purge!(opts={})
        recurse = opts[:recurse] || false
        whitelist = opts[:whitelist] || []

        exclusions = self.respond_to?(:purge_exclusions) ? purge_exclusions : []

        stale = stale_contents(recurse, exclusions, whitelist)

        if stale.empty?
          logger.debug1 _("No unmanaged contents in %{managed_dirs}, nothing to purge") % {managed_dirs: managed_directories.join(', ')}
        else
          stale.each do |fpath|
            begin
              FileUtils.rm_r(fpath, :secure => true)
              logger.info _("Removing unmanaged path %{path}") % {path: fpath}
            rescue Errno::ENOENT
              # Don't log on ENOENT since we may encounter that from recursively deleting
              # this item's parent earlier in the purge.
            rescue
              logger.debug1 _("Unable to remove unmanaged path: %{path}") % {path: fpath}
            end
          end
        end
      end
    end
  end
end
