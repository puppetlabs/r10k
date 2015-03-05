require 'r10k/feature/collection'
require 'forwardable'
require 'r10k/util/commands'

module R10K
  module Features
    @features = R10K::Feature::Collection.new

    class << self
      extend Forwardable
      def_delegators :@features, :add, :available?
    end
  end
end

R10K::Features.add(:shellgit) { R10K::Util::Commands.which('git') }

R10K::Features.add(:rugged, :libraries => 'rugged')
