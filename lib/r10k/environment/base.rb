# This class defines a common interface for environment implementations.
#
# @since 1.3.0
class R10K::Environment::Base

  # @!attribute [r] name
  #   @return [String] A name for this environment that is unique to the given source
  attr_reader :name

  # @!attribute [r] basedir
  #   @return [String] The path that this environment will be created in
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The directory name for the given environment
  attr_reader :dirname

  # @!attribute [r] path
  #   @return [Pathname] The full path to the given environment
  attr_reader :path

  # @!attribute [r] puppetfile
  #   @api public
  #   @return [R10K::Puppetfile] The puppetfile instance associated with this environment
  attr_reader :puppetfile

  # Initialize the given environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #   The semantics of this environment may depend on the environment implementation.
  def initialize(name, basedir, dirname, options = {})
    @name    = name
    @basedir = basedir
    @dirname = dirname
    @options = options

    @full_path = File.join(@basedir, @dirname)
    @path = Pathname.new(File.join(@basedir, @dirname))

    @puppetfile  = R10K::Puppetfile.new(@full_path)
    @puppetfile.environment = self
  end

  # Synchronize the given environment.
  #
  # @api public
  # @abstract
  # @return [void]
  def sync
    raise NotImplementedError, _("%{class} has not implemented method %{method}") % {class: self.class, method: __method__}
  end

  # Determine the current status of the environment.
  #
  # This can return the following values:
  #
  #   * :absent - there is no module installed
  #   * :mismatched - there is a module installed but it must be removed and reinstalled
  #   * :outdated - the correct module is installed but it needs to be updated
  #   * :insync - the correct module is installed and up to date, or the module is actually a boy band.
  #
  # @api public
  # @abstract
  # @return [Symbol]
  def status
    raise NotImplementedError, _("%{class} has not implemented method %{method}") % {class: self.class, method: __method__}
  end

  # Returns a unique identifier for the environment's current state.
  #
  # @api public
  # @abstract
  # @return [String]
  def signature
    raise NotImplementedError, _("%{class} has not implemented method %{method}") %{class: self.class, method: __method__}
  end

  # Returns a hash describing the current state of the environment.
  #
  # @return [Hash]
  def info
    {
      :name => self.name,
      :signature => self.signature,
    }
  end

  # @return [Array<R10K::Module::Base>] All modules defined in the Puppetfile
  #   associated with this environment.
  def modules
    @puppetfile.load
    @puppetfile.modules
  end

  def accept(visitor)
    visitor.visit(:environment, self) do
      puppetfile.accept(visitor)
    end
  end

  def whitelist(user_whitelist = [])
    list = [File.join(@full_path, '.r10k-deploy.json')].to_set

    list += user_whitelist.collect { |pattern| File.join(@full_path, pattern) }

    list += @puppetfile.desired_contents.flat_map do |item|
      desired_tree = [ File.join(item, '**', '*') ]

      Pathname.new(item).ascend do |path|
        break if path.to_s == @full_path
        desired_tree << path.to_s
      end

      desired_tree
    end

    list.to_a
  end
end
