require 'r10k/logging'

module R10K
module PuppetfileProvider
  class Driver

    attr_reader :basedir
    attr_reader :moduledir
    attr_reader :puppetfile_path

    include R10K::Logging

    def initialize(basedir, moduledir = nil, puppetfile_path = nil)
      @basedir = basedir
      @moduledir = moduledir
      @puppetfile_path = puppetfile_path
    end

    # TODO: Remove the same logic from R10K::Puppetfile
    def puppetfile_exists?
      @puppetfile_path ? File.exists?(@puppetfile_path) : File.exists?("#{@basedir}/Puppetfile")
    end

  end
end
end
