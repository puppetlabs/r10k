require 'r10k/action/cri_runner'

module R10K
  module Action
    module Puppetfile
      # Extend the default Cri Runner with Puppetfile specific opts
      #
      # @api private
      class CriRunner < R10K::Action::CriRunner

        include R10K::Logging

        def handle_opts(opts)
          opts[:root]       ||= wd
          super(opts)
        end

        private

        def wd
          Dir.getwd
        end
      end
    end
  end
end
