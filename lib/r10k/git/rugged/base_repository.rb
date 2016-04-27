require 'r10k/git/rugged'
require 'r10k/git/rugged/credentials'
require 'r10k/logging'

class R10K::Git::Rugged::BaseRepository

  include R10K::Logging

  # @return [Pathname] The path to this repository.
  # @note The `@path` instance variable must be set by inheriting classes on instantiation.
  attr_reader :path

  def resolve(pattern)
    object = with_repo { |repo| repo.rev_parse(pattern) }
    case object
    when NilClass
      nil
    when ::Rugged::Tag, ::Rugged::Tag::Annotation
      object.target.oid
    else
      object.oid
    end
  rescue ::Rugged::ReferenceError
    nil
  end

  def branches
    with_repo { |repo| repo.branches.each_name(:local).to_a }
  end

  def tags
    with_repo { |repo| repo.tags.each_name.to_a }
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

  def remotes
    remotes_hash = {}

    if @_rugged_repo
      @_rugged_repo.remotes.each do |remote|
        remotes_hash[remote.name] = remote.url
      end
    end

    remotes_hash
  end

  private

  def with_repo(opts={})
    if @_rugged_repo
      yield @_rugged_repo
    end
  ensure
    @_rugged_repo.close if @_rugged_repo
  end


  # Generate a lambda that can create a credentials object for the
  # authentication type in question.
  #
  # @note The Rugged API expects an object that responds to #call; the
  #   Credentials subclasses implement #call returning self so that
  #   the Credentials object can be used, or a Proc that returns a
  #   Credentials object can be used.
  #
  # @api private
  #
  # @return [Proc]
  def credentials
    R10K::Git::Rugged::Credentials.new(self)
  end

  def report_transfer(results, remote)
    logger.debug2 { "Transferred #{results[:total_objects]} objects (#{results[:received_bytes]} bytes) from '#{remote}' into #{git_dir}'" }
    nil
  end
end
