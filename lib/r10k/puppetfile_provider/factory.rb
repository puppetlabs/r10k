require 'r10k/puppetfile_provider/internal'
require 'r10k/puppetfile_provider/librarian_puppet'

module R10K
module PuppetfileProvider
class Factory

  def self.driver(basedir, moduledir = nil, puppetfile_path = nil, driver = :internal)
    case driver
      when :internal
        Internal.new(basedir, moduledir, puppetfile_path)
      when :librarian
        LibrarianPuppet.new(basedir)
      else
        raise "invalid Puppetfile provider: #{driver}"
    end
  end

end
end
end
