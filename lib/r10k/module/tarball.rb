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
    args[:version]
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
      :version   => :sha256digest,
      :type      => ::R10K::Util::Setopts::Ignore,
      :overrides => :self,

      # Type-specific options
      :sha256digest => :self,
    })

    @tarball = R10K::Tarball.new(name, @source, sha256digest: @sha256digest)
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
  def sync(opts={})
    tarball.download unless tarball.cache_valid?
    if should_sync?
      case status
      when :absent
        tarball.unpack(path.to_s)
      when :mismatched
        path.rmtree
        tarball.unpack(path.to_s)
      end
      maybe_delete_spec_dir
    end
  end

  # Return the desired version of this module
  def version
    @sha256digest || 'unversioned'
  end

  # Return the properties of the module
  #
  # @return [Hash]
  # @abstract
  def properties
    {
      :expected => @sha256digest,
      :actual   => status,
      :type     => :tarball,
    }
  end

  # Return the module's cachedir. Subclasses that implement a cache
  # will override this to return a real directory location.
  #
  # @return [String, :none]
  def cachedir
    tarball.cache_path
  end
end
