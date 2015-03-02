require 'r10k/feature'

# Store all features and indicate if they're available.
class R10K::Feature::Collection
  def initialize
    @features = {}
  end

  # @param name [Symbol] The feature to add
  # @param opts [Hash] Additional options for the feature, see {R10K::Feature}
  # @param block [Proc] An optional block to detect if this feature is present
  # @return [void]
  def add(name, opts = {}, &block)
    @features[name] = R10K::Feature.new(name, opts, &block)
  end

  # @return [true, false] Does a feature by this name exist and is it available?
  def available?(name)
    if @features.key?(name)
      @features[name].available?
    end
  end
end
