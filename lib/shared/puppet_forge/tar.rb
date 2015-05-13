
module PuppetForge
  class Tar
    require 'shared/puppet_forge/tar/mini'

    def self.instance
      Mini.new
    end
  end
end
