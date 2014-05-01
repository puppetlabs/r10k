require 'r10k/logging'

module R10K
module PuppetfileProvider
  class Driver

    attr_reader :basedir
    attr_reader :moduledir
    attr_reader :puppetfile_path

    include R10K::Logging

    PUPPET_FILE = "Puppetfile"

    def initialize(basedir, moduledir = nil, puppetfile_path = nil)
      @basedir = basedir
      @moduledir = moduledir
      @puppetfile_path = puppetfile_path || "#{basedir}/#{PUPPET_FILE}"
    end

    # TODO: Remove the same logic from R10K::Puppetfile
    def puppetfile_exists?
      File.exists?(@puppetfile_path)
    end

  end
end
end
