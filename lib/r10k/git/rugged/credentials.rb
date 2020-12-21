require 'r10k/git/rugged'
require 'r10k/git/errors'
require 'r10k/logging'

# Generate credentials for secured remote connections.
#
# @api private
class R10K::Git::Rugged::Credentials

  include R10K::Logging

  # @param repository [R10K::Git::Rugged::BaseRepository]
  def initialize(repository, credentials_from_cli = {})
    @repository = repository
    @called = 0
    @credentials_from_cli = credentials_from_cli
  end

  def call(url, username_from_url, allowed_types)
    @called += 1

    # Break out of infinite HTTP auth retry loop introduced in libgit2/rugged 0.24.0, libssh
    # auth seems to already abort after ~50 attempts.
    if @called > 50
      raise R10K::Git::GitError.new(_("Authentication failed for Git remote %{url}.") % {url: url.inspect} )
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

    if @credentials_from_cli[:sshkey_file]
      private_key = @credentials_from_cli[:sshkey_file]
      logger.debug2 _("Using per-deploy private key %{key} for URL %{url}") % {key: private_key, url: url.inspect}
    elsif per_repo_private_key
      private_key = per_repo_private_key
      logger.debug2 _("Using per-repository private key %{key} for URL %{url}") % {key: private_key, url: url.inspect}
    elsif global_private_key
      private_key = global_private_key
      logger.debug2 _("URL %{url} has no per-repository private key using '%{key}'." ) % {key: private_key, url: url.inspect}
    else
      raise R10K::Git::GitError.new(_("Git remote %{url} uses the SSH protocol but no private key was given") % {url: url.inspect}, :git_dir => @repository.path.to_s)
    end

    if !File.readable?(private_key)
      raise R10K::Git::GitError.new(_("Unable to use SSH key auth for %{url}: private key %{private_key} is missing or unreadable") % {url: url.inspect, private_key: private_key.inspect}, :git_dir => @repository.path.to_s)
    end

    Rugged::Credentials::SshKey.new(:username => user, :privatekey => private_key)
  end

  def get_plaintext_credentials(url, username_from_url)
    if @credentials_from_cli[:token]
      user = 'x-oauth-token'
      password = @credentials_from_cli[:token]
    elsif
      user = get_git_username(url, username_from_url)
      password = URI.parse(url).password || ''
    end
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
      logger.debug2 _("URL %{url} includes the username %{username}, using that user for authentication.") % {url: url.inspect, username: username_from_url}
    elsif git_user
      user = git_user
      logger.debug2 _("URL %{url} did not specify a user, using %{user} from configuration") % {url: url.inspect, user: user.inspect}
    else
      user = Etc.getlogin
      logger.debug2 _("URL %{url} did not specify a user, using current user %{user}") % {url: url.inspect, user: user.inspect}
    end

    user
  end
end
