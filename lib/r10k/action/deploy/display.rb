require 'r10k/util/setopts'
require 'r10k/deployment'
require 'r10k/logging'

module R10K
  module Action
    module Deploy
      class Display

        include R10K::Util::Setopts
        include R10K::Logging

        def initialize(opts, argv)
          @opts = opts
          @argv = argv
          setopts(opts, {
            :config     => :self,
            :puppetfile => :self,
            :trace      => :self
          })

          @level  = 4
          @indent = 0
        end

        def call
          @visit_ok = true
          deployment = R10K::Deployment.load_config(@config)
          deployment.accept(self)
          @visit_ok
        end

        include R10K::Action::Visitor

        private

        def visit_deployment(deployment)
          yield
        end

        def visit_source(source)
          source.generate_environments
          display_text("#{source.name} (#{source.basedir})")
          yield
        end

        def visit_environment(environment)
          indent do
            display_text("- " + environment.dirname)
            yield if @puppetfile
          end
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
        end

        def visit_module(mod)
          indent do
            display_text("- " + mod.title)
          end
        end

        def indent(&block)
          @indent += @level
          block.call
        ensure
          @indent -= @level
        end

        def indent_text(str)
          space = " " * @indent
          str.lines.map do |line|
            space + line
          end.join
        end

        def display_text(str)
          puts indent_text(str)
        end
      end
    end
  end
end
