require 'r10k/util/setopts'
require 'r10k/deployment'
require 'r10k/logging'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'
require 'json'

module R10K
  module Action
    module Deploy
      class Environment < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers

        attr_reader :force

        def initialize(opts, argv, settings = nil)
          settings ||= {}
          @purge_levels = settings.fetch(:deploy, {}).fetch(:purge_levels, [])
          @user_purge_whitelist = settings.fetch(:deploy, {}).fetch(:purge_whitelist, [])

          super

          # @force here is used to make it easier to reason about
          @force = !@no_force
          @argv = @argv.map { |arg| arg.gsub(/\W/,'_') }
        end

        def call
          @visit_ok = true

          expect_config!
          deployment = R10K::Deployment.new(@settings)
          check_write_lock!(@settings)

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
            logger.error _("Environment(s) \'%{environments}\' cannot be found in any source and will not be deployed.") % {environments: undeployable.join(", ")}
          end

          yield

          if @purge_levels.include?(:deployment)
            logger.debug("Purging unmanaged environments for deployment...")
            deployment.purge!
          end
        ensure
          if (postcmd = @settings[:postrun])
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
            logger.debug1(_("Environment %{env_dir} does not match environment name filter, skipping") % {env_dir: environment.dirname})
            return
          end

          started_at = Time.new

          logger.info _("Deploying environment %{env_path}") % {env_path: environment.path}

          # Sync the environment and redirect once if necessary. Use &Proc.new
          # to forward this method's block to the sync_environment! method.
          if sync_environment!(environment, &Proc.new) == :redirect

            # Preserve the environment Puppetfile, sync the redirected
            # environment, and restore the environment Puppetfile for
            # reference.
            envpf_path = environment.puppetfile.puppetfile_path
            envpf_name = environment.puppetfile.puppetfile_name
            envpf_contents = environment.puppetfile.puppetfile_contents

            # Sync to the redirected environment, but don't allow a repeat
            # redirection
            if sync_environment!(environment, &Proc.new) != :done
              raise R10K::Error.new('Redirect can only be performed once per environment, per deploy')
            end

            # Restore the environment Puppetfile to disk so that all of the
            # artifacts that contributed to building an environment are visible
            File.open(envpf_path, 'w') { |file| file.write(envpf_contents) }
          end

          if @purge_levels.include?(:environment)
            if @visit_ok
              logger.debug("Purging unmanaged content for environment '#{environment.dirname}'...")
              environment.purge!(:recurse => true, :whitelist => environment.whitelist(@user_purge_whitelist))
            else
              logger.debug("Not purging unmanaged content for environment '#{environment.dirname}' due to prior deploy failures.")
            end
          end

          write_environment_info!(environment, started_at, @visit_ok)
        end

        def sync_environment!(environment)
          status = environment.status
          environment.sync

          logger.info _("Environment %{env_dir} is now at %{env_signature}") % {env_dir: environment.dirname, env_signature: environment.signature}
          logger.debug(_("Environment %{env_dir} is new, updating all modules") % {env_dir: environment.dirname}) if status == :absent

          if (@puppetfile || status == :absent) && (yield == :redirect)
            redirect = environment.puppetfile.environment_redirect
            environment.ref = redirect[:ref]
            environment.remote = redirect[:git] if redirect[:git]
            :redirect
          else
            :done
          end
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load

          if puppetfile.environment_redirect?
            signature = puppetfile.environment.signature
            newremote = puppetfile.environment_redirect[:git]
            newref    = puppetfile.environment_redirect[:ref]
            remotestr = newremote ? "#{newremote} " : ''
            logger.info(_('Puppetfile at %{signature} redirects to %{remote}"%{ref}"') % {signature: signature, remote: remotestr, ref: newref})
            unless puppetfile.modules.empty?
              names = puppetfile.modules.map{ |m| m.name }.join(',')
              logger.info(_('Loaded modules from Puppetfile at %{signature}: %{names}') % {signature: signature, names: names})
            end
            return :redirect
          end

          yield

          if @purge_levels.include?(:puppetfile)
            logger.debug("Purging unmanaged Puppetfile content for environment '#{puppetfile.environment.dirname}'...")
            puppetfile.purge!
          end
        end

        def visit_module(mod)
          logger.info _("Deploying Puppetfile content %{mod_path}") % {mod_path: mod.path}
          mod.sync(force: @force)
        end

        def write_environment_info!(environment, started_at, success)
          File.open("#{environment.path}/.r10k-deploy.json", 'w') do |f|
            deploy_info = environment.info.merge({
              :started_at => started_at,
              :finished_at => Time.new,
              :deploy_success => success,
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
          super.merge(puppetfile: :self, cachedir: :self, :'no-force' => :self)
        end
      end
    end
  end
end
