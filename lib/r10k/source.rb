require 'r10k'
require 'r10k/keyed_factory'

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

    require 'r10k/source/base'
    require 'r10k/source/git'
  end
end
