require 'r10k/source'
require 'r10k-mocks/mock_env'

class R10K::Source::Mock < R10K::Source::Base
  R10K::Source.register(:mock, self)

  def environments
    @options[:environments].map { |n| R10K::Environment::Mock.new(n, @basedir, n) }
  end
end
