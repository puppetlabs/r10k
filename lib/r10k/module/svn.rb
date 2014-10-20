require 'r10k/module'
require 'r10k/execution'
require 'r10k/svn/working_dir'
require 'r10k/util/setopts'

class R10K::Module::SVN < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key? :svn
  end

  # @!attribute [r] expected_revision
  #   @return [String] The SVN revision that the repo should have checked out
  attr_reader :expected_revision
  alias expected_version expected_revision

  # @!attribute [r] full_path
  #   @return [Pathname] The filesystem path to the SVN repo
  attr_reader :full_path

  # @!attribute [r] username
  #   @return [String, nil] The SVN username to be passed to the underlying SVN commands
  #   @api private
  attr_reader :username

  # @!attribute [r] password
  #   @return [String, nil] The SVN password to be passed to the underlying SVN commands
  #   @api private
  attr_reader :password

  include R10K::Util::Setopts

  INITIALIZE_OPTS = {
    :svn => :url,
    :rev => :expected_revision,
    :revision => :expected_revision,
    :username => :self,
    :password => :self
  }

  def initialize(name, dirname, opts)
    super
    setopts(opts, INITIALIZE_OPTS)
    @working_dir = R10K::SVN::WorkingDir.new(@path, :username => @username, :password => @password)
  end

  def status
    if not self.exist?
      :absent
    elsif not @working_dir.is_svn?
      :mismatched
    elsif not @url == @working_dir.url
      :mismatched
    elsif not @expected_revision == @working_dir.revision
      :outdated
    else
      :insync
    end
  end

  def sync
    case status
    when :absent
      install
    when :mismatched
      reinstall
    when :outdated
      update
    end
  end

  def exist?
    path.exist?
  end

  private

  def install
    FileUtils.mkdir @dirname unless File.directory? @dirname

    @working_dir.checkout(@url, @expected_revision)
  end

  def uninstall
    path.rmtree
  end

  def reinstall
    uninstall
    install
  end

  def update
    @working_dir.update(@expected_revision)
  end
end
