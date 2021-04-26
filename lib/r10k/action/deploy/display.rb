require 'r10k/deployment'
require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'

module R10K
  module Action
    module Deploy
      class Display < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers

        def call
          expect_config!
          deployment = R10K::Deployment.new(@settings)

          if @fetch
            deployment.preload!
          end

          output = { :sources => deployment.sources.map { |source| source_info(source, @argv) } }

          case @format
          when 'json' then json_format(output)
          else yaml_format(output)
          end

          # exit 0
          true
        rescue => e
          logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          false
        end

        private

        def json_format(output)
          require 'json'
          puts JSON.pretty_generate(output)
        end

        def yaml_format(output)
          require 'yaml'
          puts output.to_yaml
        end

        def source_info(source, requested_environments = [])
          source_info = {
            :name => source.name,
            :basedir => source.basedir,
          }

          source_info[:prefix] = source.prefix if source.prefix
          source_info[:remote] = source.remote if source.respond_to?(:remote)

          select_all_envs = requested_environments.empty?
          env_list = source.environments.select { |env| select_all_envs || requested_environments.include?(env.name) }
          source_info[:environments] = env_list.map { |env| environment_info(env) }

          source_info
        end

        def environment_info(env)
          if !@modules && !@detail
            env.dirname
          else
            env_info = env.info.merge({
              :status => (env.status rescue nil),
            })

            env_info[:modules] = env.modules.map { |mod| module_info(mod) } if @modules

            env_info
          end
        end

        def module_info(mod)
          if @detail
            { :name => mod.title, :properties => mod.properties }
          else
            mod.title
          end
        end

        def allowed_initialize_opts
          super.merge({
            puppetfile: :modules,
            modules: :self,
            detail: :self,
            format: :self,
            fetch: :self
          })
        end
      end
    end
  end
end
