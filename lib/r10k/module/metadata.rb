require 'r10k/module'
require 'r10k/semver'
require 'json'

class R10K::Module::Metadata

  # @!attribute [r] name
  #   @return [String] The module name
  attr_reader :name

  # @!attribute [r] author
  #   @return [String] The module author username
  attr_reader :author

  # @!attribute [r] version
  #   @return [R10K::SemVer] The module version
  attr_reader :version

  # @param metadata_path [Pathname] The file path to the metadata
  def initialize(metadata_path)
    @metadata_path = metadata_path

    @version = R10K::SemVer::MIN
  end

  # Does the metadata file itself exist?
  def exist?
    @metadata_path.file? and @metadata_path.readable?
  end

  # Attempt to read the metadata file
  def read
    if self.exist?
      hash = JSON.parse(@metadata_path.read)
      attributes_from_hash(hash)
    end
  rescue JSON::ParserError
    false
  end

  private

  def attributes_from_hash(json)
    @author, _, @name = json['name'].partition('-')
    @version = R10K::SemVer.new(json['version'])
  end
end
