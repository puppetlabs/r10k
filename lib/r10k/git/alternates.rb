require 'pathname'

# Manage `$GIT_DIR/objects/info/alternates`
#
# @see man gitrepository-layout(5)
class R10K::Git::Alternates

  # @attribute [r] file
  #   @return [Pathname] The alternates file
  attr_reader :file

  # @param git_dir [String] The path to the git repository
  def initialize(git_dir)
    @file = Pathname.new(File.join(git_dir, 'objects', 'info', 'alternates'))
  end

  def to_a
    read()
  end

  def <<(path)
    write(to_a << path)
  end

  def include?(path)
    to_a.include?(path)
  end

  private

  def write(entries)
    if ! @file.parent.directory?
      raise R10K::Git::GitError, "Cannot write #{@file.to_path}; parent directory does not exist"
    end
    @file.open("w") do |fh|
      entries.each do |entry|
        fh.puts(entry)
      end
    end
  end

  def read
    entries = []
    if @file.file?
      entries = @file.readlines.map(&:chomp)
    end
    entries
  end
end
