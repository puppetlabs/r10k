require 'r10k/git'

begin
  require 'rugged'
rescue LoadError
end

module R10K
  module Git
    module Rugged
      require 'r10k/git/rugged/bare_repository'
      require 'r10k/git/rugged/working_repository'
      require 'r10k/git/rugged/cache'
      require 'r10k/git/rugged/thin_repository'
    end
  end
end
