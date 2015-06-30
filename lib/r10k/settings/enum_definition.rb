require 'r10k/settings/definition'

module R10K
  module Settings
    class EnumDefinition < R10K::Settings::Definition

      def validate
        if @value
          if !@enum.include?(@value)
            raise ArgumentError, "Setting #{@name} should be one of #{@enum.inspect}, not '#{@value}'"
          end
        end
      end

      private

      def allowed_initialize_opts
        super.merge({:enum => true})
      end
    end
  end
end
