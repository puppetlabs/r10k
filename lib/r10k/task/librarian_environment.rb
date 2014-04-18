require 'r10k/task'

module R10K
module Task
module LibrarianEnvironment
  class Install < R10K::Task::Base
    def initialize(librarian)
      @librarian = librarian
    end

    def call
      logger.info "Installing modules for environment at #{@librarian.environment_root}"
      @librarian.install!
    end
  end

end
end
end
