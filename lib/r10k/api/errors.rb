module R10K
  module API
    module Errors
      class UnresolvableError < StandardError
        def initialize(message, modules=nil)
          if modules && modules.respond_to?(:each)
            modules.each { |m| message << "\n#{m[:name]} could not be resolved: #{m[:error].message}" }
          end

          super(message)
        end
      end
    end
  end
end
