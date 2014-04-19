require 'r10k/puppetfile_provider/driver'

require 'librarian/action/install'
require 'librarian/puppet/extension' # patches Install to be non-destructive

module R10K
module PuppetfileProvider
  class LibrarianPuppet < Driver

    def sync_modules
      sync
    end

    def sync
      execute_if_puppetfile_exists do
        Librarian::Action::Install.new(environment, {}).run
      end
    end

    def purge
      if environment.config_db.local['destructive'] == 'true'
        sync
      else
        while_destructive do
          sync
        end
      end

    end

    private

    def environment
      @environment ||= Librarian::Puppet::Environment.new(:pwd => @basedir)
    end

    def while_destructive
      environment.config_db.local['destructive'] = 'true'
      yield if block_given?
      ensure
        environment.config_db.local['destructive'] = 'false'
    end

    # TODO: remove this same logic from R10K::Puppetfile and implement on the base class
    def execute_if_puppetfile_exists
      if puppetfile_exists?
        yield if block_given?
      else
        logger.debug "Puppetfile in #{@basedir} missing or unreadable"
      end
    end


  end
end
end

