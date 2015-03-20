require 'r10k/git'

# :nocov:
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
