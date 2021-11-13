require 'r10k/module'
require 'r10k/util/setopts'
require 'r10k/tarball'

# This class defines a tarball source module implementation
class R10K::Module::Tarball < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a?(Hash) && args[:type].to_s == 'tarball'
  rescue
    false
  end

  def self.statically_defined_version(name, args)
    args[:version] || args[:checksum]
  end

  # @!attribute [r] tarball
  #   @api private
  #   @return [R10K::Tarball]
  attr_reader :tarball

  include R10K::Util::Setopts

  def initialize(name, dirname, opts, environment=nil)
    super
    setopts(opts, {
      # Standard option interface
      :source    => :self,
      :version   => :checksum,
      :type      => ::R10K::Util::Setopts::Ignore,
      :overrides => :self,

      # Type-specific options
      :checksum => :self,
    })

    @tarball = R10K::Tarball.new(name, @source, checksum: @checksum)
  end

  # Return the status of the currently installed module.
  #
  # @return [Symbol]
  def status
    if not path.exist?
      :absent
    elsif not (tarball.cache_valid? && tarball.insync?(path.to_s))
      :mismatched
    else
      :insync
    end
  end

  # Synchronize this module with the indicated state.
  # @param [Hash] opts Deprecated
  # @return [Boolean] true if the module was updated, false otherwise
  def sync(opts={})
    tarball.get unless tarball.cache_valid?
    if should_sync?
      case status
      when :absent
        tarball.unpack(path.to_s)
      when :mismatched
        path.rmtree
        tarball.unpack(path.to_s)
      end
      maybe_delete_spec_dir
      true
    else
      false
    end
  end

  # Return the desired version of this module
  def version
    @checksum || 'unversioned'
  end

  # Return the properties of the module
  #
  # @return [Hash]
  # @abstract
  def properties
    {
      :expected => @checksum,
      :actual   => status,
      :type     => :tarball,
    }
  end

  # Tarball caches are files, not directories. An important purpose of this
  # method is to indicate where the cache "path" is, for locking/parallelism,
  # so for the Tarball module type, the relevant path location is returned.
  #
  # @return [String] The path this module will cache its tarball source to
  def cachedir
    tarball.cache_path
  end
end
