require 'pathname'

# Manage `$GIT_DIR/objects/info/alternates`
#
# @see man gitrepository-layout(5)
class R10K::Git::Alternates

  # @attribute [r] file
  #   @return [Pathname] The alternates file
  attr_reader :file

  # @param git_dir [Pathname] The path to the git repository
  def initialize(git_dir)
    @file = git_dir + File.join('objects', 'info', 'alternates')
    @entries = []
  end

  def add(path)
    write(to_a << path)
  end
  alias << add

  # Conditionally add path to the alternates file
  #
  # @param path [String] The file path to add to the file if not already present
  # @return [true, false] If the entry was added.
  def add?(path)
    paths = read()

    add_entry = !paths.include?(path)

    if add_entry
      paths << path
      write(paths)
    end

    add_entry
  end

  def include?(path)
    to_a.include?(path)
  end

  def write(entries)
    if ! @file.parent.directory?
      raise R10K::Git::GitError, "Cannot write #{@file}; parent directory does not exist"
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
  alias to_a read
end
