require 'r10k/git'

# :nocov:
#
# @deprecated This has been replaced by the ShellGit provider and the
#   StatefulRepository class and will be removed in 2.0.0
#
# @api private
class R10K::Git::RemoteHead < R10K::Git::Head

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: no associated git repository"
    else
      @repository.resolve_head("refs/remotes/cache/#{@head}")
    end
  end
end
# :nocov:
