require 'r10k/deployment'
require 'r10k/action/base'

module R10K
  module Action
    module Deploy
      class Display < R10K::Action::Base

        def call
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

        def source_info(source, argv=[])
          source_info = {
            :name => source.name,
            :basedir => source.basedir,
          }

          source_info[:prefix] = source.prefix if source.prefix
          source_info[:remote] = source.remote if source.respond_to?(:remote)

          env_list = source.environments.select { |env| argv.empty? || argv.include?(env.name) }
          source_info[:environments] = env_list.map { |env| environment_info(env) }

          source_info
        end

        def environment_info(env)
          if !@puppetfile && !@detail
            env.dirname
          else
            env_info = env.info.merge({
              :status => (env.status rescue nil),
            })

            env_info[:modules] = env.modules.map { |mod| module_info(mod) } if @puppetfile

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
          super.merge(puppetfile: :self, detail: :self, format: :self, fetch: :self)
        end
      end
    end
  end
end
