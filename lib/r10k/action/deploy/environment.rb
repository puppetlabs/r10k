require 'r10k/util/setopts'
require 'r10k/deployment'
require 'r10k/logging'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/deployment/write_lock'
require 'json'

module R10K
  module Action
    module Deploy
      class Environment < R10K::Action::Base

        include R10K::Deployment::WriteLock

        def initialize(opts, argv)
          @purge = true
          super
          @argv = @argv.map { |arg| arg.gsub(/\W/,'_') }
        end

        def call
          @visit_ok = true

          deployment = R10K::Deployment.load_config(@config, :cachedir => @cachedir)
          check_write_lock!(deployment.config.settings)

          deployment.accept(self)
          @visit_ok
        end

        include R10K::Action::Visitor

        private

        def visit_deployment(deployment)
          # Ensure that everything can be preloaded. If we cannot preload all
          # sources then we can't fully enumerate all environments which
          # could be dangerous. If this fails then an exception will be raised
          # and execution will be halted.
          deployment.preload!
          deployment.validate!

          undeployable = undeployable_environment_names(deployment.environments, @argv)
          if !undeployable.empty?
            @visit_ok = false
            logger.error "Environment(s) \'#{undeployable.join(", ")}\' cannot be found in any source and will not be deployed."
          end

          yield

          deployment.purge! if @purge

        ensure
          if (postcmd = deployment.config.setting(:postrun))
            subproc = R10K::Util::Subprocess.new(postcmd)
            subproc.logger = logger
            subproc.execute
          end
        end

        def visit_source(source)
          yield
        end

        def visit_environment(environment)
          if !(@argv.empty? || @argv.any? { |name| environment.dirname == name })
            logger.debug1("Environment #{environment.dirname} does not match environment name filter, skipping")
            return
          end

          started_at = Time.new

          status = environment.status
          logger.info "Deploying environment #{environment.path}"

          environment.sync
          logger.info "Environment #{environment.dirname} is now at #{environment.signature}"

          if status == :absent || @puppetfile
            if status == :absent
              logger.debug("Environment #{environment.dirname} is new, updating all modules")
            end

            yield
          end

          write_environment_info!(environment, started_at)
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
          puppetfile.purge!
        end

        def visit_module(mod)
          logger.info "Deploying module #{mod.path}"
          mod.sync
        end

        def write_environment_info!(environment, started_at)
          File.open("#{environment.path}/.r10k-deploy.json", 'w') do |f|
            deploy_info = environment.info.merge({
              :started_at => started_at,
              :finished_at => Time.new,
            })

            f.puts(JSON.pretty_generate(deploy_info))
          end
        end

        def undeployable_environment_names(environments, expected_names)
          if expected_names.empty?
            []
          else
            known_names = environments.map(&:dirname)
            expected_names - known_names
          end
        end

        def allowed_initialize_opts
          super.merge(puppetfile: :self, cachedir: :self, purge: true)
        end
      end
    end
  end
end
