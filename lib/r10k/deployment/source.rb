require 'r10k/source'

module R10K
class Deployment
class Source
  # Create a new source from a hash representation
  #
  # @param name [String] The name of the source
  # @param opts [Hash] The properties to use for the source
  # @param prefix [true, false] Whether to prefix the source name to created
  #   environments
  #
  # @option opts [String] :remote The git remote for the given source
  # @option opts [String] :basedir The directory to create environments in
  # @option opts [true, false] :prefix Whether the environment names should
  #   be prefixed by the source name. Defaults to false. This takes precedence
  #   over the `prefix` argument
  #
  # @return [R10K::Deployment::Source]
  def self.vivify(name, attrs, prefix = false)
    remote  = (attrs.delete(:remote) || attrs.delete('remote'))
    basedir = (attrs.delete(:basedir) || attrs.delete('basedir'))
    prefix_config = (attrs.delete(:prefix) || attrs.delete('prefix'))
    prefix_outcome = prefix_config.nil? ? prefix : prefix_config

    raise ArgumentError, "Unrecognized attributes for #{self.name}: #{attrs.inspect}" unless attrs.empty?
    new(name, remote, basedir, prefix_outcome)
  end

  def self.new(name, remote, basedir, prefix)
    R10K::Source::Git.new(basedir, name, {:prefix => prefix, :remote => remote})
  end
end
end
end
