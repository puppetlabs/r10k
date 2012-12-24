require 'r10k/cli/module'
require 'r10k/deployment'
require 'cri'

module R10K::CLI::Module
  module List
    def self.command
      @cmd ||= Cri::Command.define do
        name  'list'
        usage 'list'
        summary 'List modules that are instantiated in environments'

        run do |opts, args, cmd|
          deployment = R10K::Deployment.instance
          env_list   = deployment.environments

          update_cache = (defined? opts[:update]) ? (opts[:update] == 'true') : false

          if opts[:environment]
            environments = env_list.select {|env| env.name == opts[:environment]}
          else
            environments = env_list
          end

          printree = {}

          environments.each do |env|
            module_names = env.modules.map(&:name)

            printree[env.name] = module_names
          end

          printree.each_pair do |env_name, mod_list|
            puts "  - #{env_name}"
            mod_list.each do |mod|
              puts "      #{mod}"
            end
          end
        end
      end
    end
  end
  self.command.add_command(List.command)
end

