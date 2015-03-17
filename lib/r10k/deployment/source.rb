require 'r10k/source'
require 'r10k/util/symbolize_keys'

module R10K
class Deployment
# :nocov:
class Source
  # Create a new source from a hash representation
  #
  # @param name [String] The name of the source
  # @param opts [Hash] The properties to use for the source
  #
  # @option opts [String] :remote The git remote for the given source
  # @option opts [String] :basedir The directory to create environments in
  # @option opts [true, false] :prefix Whether the environment names should
  #   be prefixed by the source name. Defaults to false.
  #
  # @deprecated
  # @return [R10K::Source::Base]
  def self.vivify(name, attrs)
    R10K::Util::SymbolizeKeys.symbolize_keys!(attrs)

    remote  = attrs.delete(:remote)
    basedir = attrs.delete(:basedir)
    prefix  = attrs.delete(:prefix)

    raise ArgumentError, "Unrecognized attributes for #{self.name}: #{attrs.inspect}" unless attrs.empty?
    new(name, remote, basedir, prefix)
  end

  def self.new(name, remote, basedir, prefix)
    R10K::Source::Git.new(name, basedir, {:prefix => prefix, :remote => remote})
  end
end
end
# :nocov:
end
