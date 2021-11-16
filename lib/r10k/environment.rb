module R10K
  module Environment
    def self.factory
      @factory ||= R10K::KeyedFactory.new
    end

    def self.register(key, klass)
      factory.register(key, klass)
    end

    def self.retrieve(key)
      factory.retrieve(key)
    end

    def self.generate(type, name, basedir, dirname, options = {})
      factory.generate(type, name, basedir, dirname, options)
    end

    def self.from_hash(name, hash)
      R10K::Util::SymbolizeKeys.symbolize_keys!(hash)

      basedir = hash.delete(:basedir)
      dirname = hash.delete(:dirname) || name

      type = hash.delete(:type)
      type = type.is_a?(String) ? type.to_sym : type

      generate(type, name, basedir, dirname, hash)
    end

    require 'r10k/environment/base'
    require 'r10k/environment/with_modules'
    require 'r10k/environment/plain'
    require 'r10k/environment/bare'
    require 'r10k/environment/git'
    require 'r10k/environment/svn'
    require 'r10k/environment/tarball'
  end
end
