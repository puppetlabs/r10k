require 'r10k/module'
require 'r10k/svn/working_dir'

class R10K::Module::SVN

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
    else
      :insync
    end
  end

  def sync

  end

  def exist?
    @full_path.exist?
  end

  private

  def parse_options(hash)
    hash.each_pair do |key, value|
      case key
      when :rev, :revision
        @expected_revision = value
      when :svn_path
        @svn_path = value
      end
    end
  end
end
