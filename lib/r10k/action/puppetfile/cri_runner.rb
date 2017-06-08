require 'r10k/action/cri_runner'

module R10K
  module Action
    module Puppetfile
      # Extend the default Cri Runner to use the PUPPETFILE environment
      # variables.
      #
      # @api private
      # @deprecated The use of these environment variables is deprecated and
      #   will be removed in 3.0.0.
      class CriRunner < R10K::Action::CriRunner

        include R10K::Logging

        def handle_opts(opts)
          opts[:root]       ||= wd
          if env['PUPPETFILE_DIR'] || env['PUPPETFILE']
            logger.warn _("The use of the PUPPETFILE and PUPPETFILE_DIR environment variables is deprecated.")
          end
          opts[:moduledir]  ||= env['PUPPETFILE_DIR']
          opts[:puppetfile] ||= env['PUPPETFILE']
          super(opts)
        end

        private

        def env
          ENV
        end

        def wd
          Dir.getwd
        end
      end
    end
  end
end
