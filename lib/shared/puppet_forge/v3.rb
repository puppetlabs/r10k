module PuppetForge
  module V3
    # Normalize a module name to use a hyphen as the separator between the
    # author and module.
    #
    # @example
    #   PuppetForge::V3.normalize_name('my/module') #=> 'my-module'
    #   PuppetForge::V3.normalize_name('my-module') #=> 'my-module'
    def self.normalize_name(name)
      name.tr('/', '-')
    end
  end
end
