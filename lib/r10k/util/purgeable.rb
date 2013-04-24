require 'fileutils'
module R10K
module Util
module Purgeable
  # Mixin for purging stale directory contents.
  #
  # @abstract Classes using this mixin need to implement {#basedir} and
  #   {#desired_contents}

  # @!method desired_contents
  #   @abstract Including classes must implement this method to list the
  #     expected filenames of basedir
  #   @return [Array<String>] A list of directory contents that should be present

  # @!method basedir
  #   @abstract Including classes must implement this method to return the
  #     path to the directory that can be purged
  #   @return [String] The path to the directory to be purged

  # @return [Array<String>] The present directory entries in `self.basedir`
  def current_contents
    dir = self.basedir
    glob_exp = File.join(dir, '*')

    Dir.glob(glob_exp).map do |fname|
      File.basename fname
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

  # Forcibly remove all unmanaged content in `self.basedir`
  def purge
    stale_contents.each do |fname|
      fpath = File.join(self.basedir, fname)
      FileUtils.rm_rf fpath, :secure => true
    end
  end

end
end
end
