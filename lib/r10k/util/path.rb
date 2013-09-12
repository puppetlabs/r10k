
module R10K; end
module R10K::Util; end

module R10K::Util::Path

  # Make all functions here module functions, not instance functions.
  module_function

  # Check if path is absolute
  #
  # @param [String] path
  #
  # @return [Boolean]
  def is_absolute?(path)
    File.expand_path(path) == path
  end

  # Check if path is relative
  #
  # @param [String] path
  #
  # @return [Boolean]
  def is_relative?(path)
    File.expand_path(path) != path
  end
end
