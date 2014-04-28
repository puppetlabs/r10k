require 'r10k'
require 'r10k/keyed_factory'
require 'r10k/util/core_ext/hash_ext'

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
      hash.extend R10K::Util::CoreExt::HashExt::SymbolizeKeys
      hash.symbolize_keys!

      basedir = hash.delete(:basedir)

      type = hash.delete(:type)
      type = type.is_a?(String) ? type.to_sym : type

      generate(type, basedir, name, hash)
    end

    require 'r10k/source/base'
    require 'r10k/source/git'
  end
end
