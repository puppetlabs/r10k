require 'rake'
require 'rake/tasklib'

module R10KTasks
  class RakeTask < ::Rake::TaskLib
    def initialize(*args)
      namespace :r10k do
        desc "Syntax check Puppetfile"
        task :syntax do
          require 'r10k/action/puppetfile/check'

          puppetfile = R10K::Action::Puppetfile::Check.new({
            :root => ".",
            :moduledir => nil,
            :puppetfile => nil
          }, '')
          puppetfile.call
        end
      end
    end
  end
end

R10KTasks::RakeTask.new
