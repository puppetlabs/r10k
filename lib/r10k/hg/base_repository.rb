require 'r10k/hg'
require 'r10k/logging'
require 'r10k/util/subprocess'

class R10K::Hg::BaseRepository

  # @abstract
  # @return [Pathname] The path to the Mercurial directory
  def hg_dir
    raise NotImplementedError
  end

  def add_path(path_name, remote)
    hgrc = File.join(hg_dir.to_s, '.hg/hgrc')

    hgrc_lines = File.readlines(hgrc)

    index = hgrc_lines.index { |line| line =~ /\s*\[paths\]\s*\n/ } || -1

    if index == -1
      hgrc_lines.insert( index, "[paths]\n")
    else
      index = index + 1
    end

    hgrc_lines.insert( index, "#{path_name} = #{remote}\n")

    File.write(hgrc, hgrc_lines.join(''))
  end

  # Resolve the given Mercurial revision to a commit
  #
  # @param pattern [String] The Mercurial revision to resolve
  # @return [String, nil] The commit SHA if the revision could be resolved, nil otherwise.
  def resolve(pattern)
    result = hg ['log', '--rev', pattern, '--template', "{node}"], :path => hg_dir.to_s, :raise_on_fail => false
    if result.success?
      result.stdout
    end
  end

  # @return [Array<String>] All branches in this repository
  def branches
    output = hg ['branches', '--template', '{branch}\n'], :path => hg_dir.to_s
    output.stdout.split("\n")
  end

  # @return [Array<String>] All tags in this repository
  def tags
    output = hg ['tags', '--template', '{tag}\n'], :path => hg_dir.to_s
    output.stdout.split("\n")
  end

  # @return [Symbol] The type of the given ref, one of :branch, :tag, :commit, or :unknown
  def ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif tags.include? pattern
      :tag
    elsif resolve(pattern)
      :commit
    else
      :unknown
    end
  end

  include R10K::Logging

  private

  # Wrap hg commands
  #
  # @param cmd [Array<String>] cmd The arguments for the Mercurial prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :raise_on_fail
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The Mercurial command output
  def hg(cmd, opts = {})
    raise_on_fail = opts.fetch(:raise_on_fail, true)

    argv = %w{hg}

    if opts[:path]
      argv << "--repository"   << File.join(opts[:path])
    end

    argv.concat(cmd)

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = raise_on_fail
    subproc.logger = self.logger

    result = subproc.execute

    result
  end
end
