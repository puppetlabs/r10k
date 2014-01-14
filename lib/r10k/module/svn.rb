require 'r10k/module'
require 'r10k/execution'
require 'r10k/logging'
require 'r10k/svn/working_dir'

class R10K::Module::SVN < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key? :svn
  end

  # @!attribute [r] expected_revision
  #   @return [String] The SVN revision that the repo should have checked out
  attr_reader :expected_revision
  alias expected_version expected_revision

  # @!attribute [r] svn_path
  #   @return [String] The path inside of the SVN repository to have checked out
  attr_reader :svn_path

  # @!attribute [r] full_path
  #   @return [Pathname] The filesystem path to the SVN repo
  attr_reader :full_path

  def initialize(name, basedir, args)
    @name = name
    @basedir = basedir

    parse_options(args)

    @full_path = Pathname.new(File.join(@basedir, @name))
    @working_dir = R10K::SVN::WorkingDir.new(@full_path)
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
    @full_path.exist?
  end

  private

  def install
    FileUtils.mkdir @basedir unless File.directory? @basedir

    args = ["checkout", @url, @full_path.to_s]
    if @expected_revision
      args << '-r' << @expected_revision
    end

    svn args, @basedir.to_s
  end

  def uninstall
    @full_path.unlink
  end

  def reinstall
    uninstall
    install
  end

  def update
    args = %w[update]

    if @expected_revision
      args << "-r" << @expected_revision
    end

    svn args, @full_path.to_s
  end

  def parse_options(hash)
    hash.each_pair do |key, value|
      case key
      when :svn
        @url = value
      when :rev, :revision
        @expected_revision = value
      when :svn_path
        @svn_path = value
      end
    end
  end

  include R10K::Logging
  include R10K::Execution

  def svn(args, path = @full_path)

    cmd = "svn #{args.join(' ')}"
    log_event = "#{cmd.inspect}, repository: #{path}"

    execute(cmd, :event => log_event, :cwd => path.to_s)
  end
end
