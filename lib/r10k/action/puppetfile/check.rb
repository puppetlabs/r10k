require 'r10k/action/base'
require 'r10k/errors/formatting'
require 'r10k/module_loader/puppetfile'

module R10K
  module Action
    module Puppetfile
      class Check < R10K::Action::Base

        def call
          options = { basedir: @root }
          options[:overrides] = {}
          options[:overrides][:modules] = { default_ref: @settings.dig(:git, :default_ref) }
          options[:moduledir] = @moduledir if @moduledir
          options[:puppetfile] = @puppetfile if @puppetfile

          loader = R10K::ModuleLoader::Puppetfile.new(**options)
          begin
            loader.load!
            loader.modules.each do |mod|
              if mod.instance_of?(R10K::Module::Git)
                mod.validate_ref_defined
              end
            end
            $stderr.puts _("Syntax OK")
            true
          rescue => e
            $stderr.puts R10K::Errors::Formatting.format_exception(e, @trace)
            false
          end
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self)
        end
      end
    end
  end
end

