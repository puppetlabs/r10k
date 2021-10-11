module R10K
  module Action
    module Puppetfile
      require 'r10k/action/puppetfile/cri_runner'
      require 'r10k/action/puppetfile/install'
      require 'r10k/action/puppetfile/check'
      require 'r10k/action/puppetfile/purge'
      require 'r10k/action/puppetfile/resolve'
    end
  end
end
