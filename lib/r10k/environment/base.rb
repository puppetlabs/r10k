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

  def initialize(name, basedir, dirname, options = {})
    @name    = name
    @basedir = basedir
    @dirname = dirname
    @options = options

    @full_path = File.join(@basedir, @dirname)
  end

  def sync
    raise NotImplementedError, "#{self.class} has not implemented method #{__method__}"
  end
end
