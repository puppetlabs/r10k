require 'r10k/git/rugged'
require 'r10k/logging'

class R10K::Git::Rugged::BaseRepository

  include R10K::Logging

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

  private

  def with_repo
    yield @_rugged_repo if @_rugged_repo
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
    Proc.new do |url, username_from_url, allowed_types|
      private_key = R10K::Git.settings[:private_key]
      git_user    = R10K::Git.settings[:username]

      if private_key.nil?
        raise R10K::Git::GitError.new("Git remote #{url.inspect} uses the SSH protocol but no private key was given", :git_dir => @path.to_s)
      end

      if !username_from_url.nil?
        user = username_from_url
      elsif git_user
        user = git_user
        logger.debug1 "URL #{url.inspect} did not specify an SSH user, using #{user.inspect} from configuration"
      else
        user = Etc.getlogin
        logger.debug1 "URL #{url.inspect} did not specify an SSH user, using current user #{user.inspect}"
      end

      Rugged::Credentials::SshKey.new(:username => user, :privatekey => private_key)
    end
  end
end
