require 'r10k'
require 'r10k/keyed_factory'
require 'r10k/util/symbolize_keys'

module R10K
  module Source
    def self.factory
      @factory ||= R10K::KeyedFactory.new
    end

    def self.register(key, klass)
      factory.register(key, klass)
    end

    def self.retrieve(key)
      factory.retrieve(key)
    end

    def self.generate(type, basedir, name, options = {})
      factory.generate(type, basedir, name, options)
    end

    def self.from_hash(name, hash)
      R10K::Util::SymbolizeKeys.symbolize_keys!(hash)

      basedir = hash.delete(:basedir)

      type = hash.delete(:type)
      type = type.is_a?(String) ? type.to_sym : type

      generate(type, name, basedir, hash)
    end

    require 'r10k/source/base'
    require 'r10k/source/hash'
    require 'r10k/source/git'
    require 'r10k/source/svn'
  end
end
