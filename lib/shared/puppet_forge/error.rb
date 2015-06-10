module PuppetForge
  class Error < RuntimeError
    attr_accessor :original
    def initialize(message, original=nil)
      super(message)
      @original = original
    end
  end

  class ExecutionFailure < PuppetForge::Error
  end

  class InvalidPathInPackageError < PuppetForge::Error
    def initialize(options)
      @entry_path = options[:entry_path]
      @directory  = options[:directory]
      super "Attempt to install file into #{@entry_path.inspect} under #{@directory.inspect}"
    end

    def multiline
      <<-MSG.strip
Could not install package
  Package attempted to install file into
  #{@entry_path.inspect} under #{@directory.inspect}.
      MSG
    end
  end

  class ModuleNotFound < PuppetForge::Error
  end

  class ModuleReleaseNotFound < PuppetForge::Error
  end
end
