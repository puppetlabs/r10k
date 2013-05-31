require 'fileutils'
module R10K
module Util
module Purgeable
  # Mixin for purging stale directory contents.
  #
  # @abstract Classes using this mixin need to implement {#managed_directory} and
  #   {#desired_contents}

  # @!method desired_contents
  #   @abstract Including classes must implement this method to list the
  #     expected filenames of managed_directory
  #   @return [Array<String>] A list of directory contents that should be present

  # @!method managed_directory
  #   @abstract Including classes must implement this method to return the
  #     path to the directory that can be purged
  #   @return [String] The path to the directory to be purged

  # @return [Array<String>] The present directory entries in `self.managed_directory`
  def current_contents
    @dirs = []
    @dirs <<  self.managed_directory
    @fnames = []

    @dirs.flatten.each do |dir|
      glob_exp = File.join(dir, '*')
      @fnames << Dir.glob(glob_exp)
    end

    @fnames.flatten

  end

  # @return [Array<String>] Directory contents that are expected but not present
  def pending_contents
    desired_contents - current_contents
  end

  # @return [Array<String>] Directory contents that are present but not expected
  def stale_contents
    current_contents - desired_contents
  end

  # Forcibly remove all unmanaged content in `self.managed_directory`
  def purge!
    stale_contents.each do |fname|
      FileUtils.rm_rf fname, :secure => true
    end
  end

end
end
end
