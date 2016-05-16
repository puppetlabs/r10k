require 'r10k/git/rugged'
require 'r10k/git/errors'
require 'r10k/logging'

# Generate credentials for secured remote connections.
#
# @api private
class R10K::Git::Rugged::Credentials

  include R10K::Logging

  # @param repository [R10K::Git::Rugged::BaseRepository]
  def initialize(repository)
    @repository = repository
    @called = 0
  end

  def call(url, username_from_url, allowed_types)
    @called += 1

    # Break out of infinite HTTP auth retry loop introduced in libgit2/rugged 0.24.0, libssh
    # auth seems to already abort after ~50 attempts.
    if @called > 50
      raise R10K::Git::GitError.new("Authentication failed for Git remote #{url.inspect}.")
    end

    if allowed_types.include?(:ssh_key)
      get_ssh_key_credentials(url, username_from_url)
    elsif allowed_types.include?(:plaintext)
      get_plaintext_credentials(url, username_from_url)
    else
      get_default_credentials(url, username_from_url)
    end
  end

  def get_ssh_key_credentials(url, username_from_url)
    user = get_git_username(url, username_from_url)

    per_repo_private_key = nil
    if per_repo_settings = R10K::Git.get_repo_settings(url)
      per_repo_private_key = per_repo_settings[:private_key]
    end

    global_private_key = R10K::Git.settings[:private_key]

    if per_repo_private_key
      private_key = per_repo_private_key
      logger.debug2 "Using per-repository private key #{private_key} for URL #{url.inspect}"
    elsif global_private_key
      private_key = global_private_key
      logger.debug2 "URL #{url.inspect} has no per-repository private key using '#{private_key}'."
    else
      raise R10K::Git::GitError.new("Git remote #{url.inspect} uses the SSH protocol but no private key was given", :git_dir => @repository.path.to_s)
    end

    if !File.readable?(private_key)
      raise R10K::Git::GitError.new("Unable to use SSH key auth for #{url.inspect}: private key #{private_key.inspect} is missing or unreadable", :git_dir => @repository.path.to_s)
    end

    Rugged::Credentials::SshKey.new(:username => user, :privatekey => private_key)
  end

  def get_plaintext_credentials(url, username_from_url)
    user = get_git_username(url, username_from_url)
    password = URI.parse(url).password || ''
    Rugged::Credentials::UserPassword.new(username: user, password: password)
  end

  def get_default_credentials(url, username_from_url)
    Rugged::Credentials::Default.new
  end

  def get_git_username(url, username_from_url)
    git_user = R10K::Git.settings[:username]

    user = nil

    if !username_from_url.nil?
      user = username_from_url
      logger.debug2 "URL #{url.inspect} includes the username #{username_from_url}, using that user for authentication."
    elsif git_user
      user = git_user
      logger.debug2 "URL #{url.inspect} did not specify a user, using #{user.inspect} from configuration"
    else
      user = Etc.getlogin
      logger.debug2 "URL #{url.inspect} did not specify a user, using current user #{user.inspect}"
    end

    user
  end
end
