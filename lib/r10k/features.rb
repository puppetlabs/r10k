require 'r10k/feature/collection'
require 'forwardable'

module R10K
  module Features
    @features = R10K::Feature::Collection.new

    class << self
      extend Forwardable
      def_delegators :@features, :add, :available?
    end
  end
end
