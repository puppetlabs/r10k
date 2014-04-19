require 'r10k/puppetfile_provider/internal'
require 'r10k/puppetfile_provider/librarian_puppet'

module R10K
module PuppetfileProvider
class Factory

  def self.driver(basedir, moduledir = nil, puppetfile_path = nil)
    Internal.new(basedir, moduledir, puppetfile_path)
    # TODO: Implement a way to swap between providers
    #LibrarianPuppet.new(basedir)
  end

end
end
end
