require 'r10k/module'
require 'r10k/logging'

# A module type that can be used to include modules from a local directory
# e.g. for modules which are updated by some external mechanism
class R10K::Module::LocalDirectory < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a?(Hash) && args[:local_directory]
  end

  attr_accessor :local_directory
  attr_accessor :expected_version

  def initialize(title, dirname, args, environment=nil)
    super

    @local_directory = args[:local_directory]

    @metadata_file = R10K::Module::MetadataFile.new(path + 'metadata.json')
    @metadata = @metadata_file.read

    @expected_version = args[:version] || current_version || :latest
  end

  # @return [String] The version of the currently installed module
  def current_version
    @metadata ? @metadata.version : nil
  end

  include R10K::Logging

  def properties
    {
        :expected => expected_version,
        :actual   => current_version,
        :type     => :local_directory
    }
  end

  def exist?
    path.exist?
  end

  # Determine the status of the local directory module.
  #
  # @return [Symbol] :absent If the directory doesn't exist
  # @return [Symbol] :outdated If the installed module is older than expected
  # @return [Symbol] :no_metadata If no metadata file is available
  # @return [Symbol] :insync If the module is in the desired state
  def status
    if not self.exist?
      return :absent
    elsif expected_version == :current || :keep
      return :insync
    elsif not File.exist?(@path + 'metadata.json')
      # The directory exists but doesn't have a metadata file; it probably
      # isn't a forge module.
      return :no_metadata
    end

    # The module is present and has a metadata file, read the metadata to
    # determine the state of the module.
    @metadata = @metadata_file.read(@path + 'metadata.json')


    if expected_version && (expected_version != @metadata.version)
      return :outdated
    end

    return :insync
  end

  def reinstall
    FileUtils.rm_rf full_path
    parent_path = @path.parent
    if !parent_path.exist?
      parent_path.mkpath
    end
    FileUtils.cp_r(local_directory, full_path)
  end

  def sync(opts={})
    reinstall unless status == :insync
  end
end
