require 'r10k/settings/definition'

module R10K
  module Settings
    class EnumDefinition < R10K::Settings::Definition

      def validate
        if @value
          if @multi && @value.respond_to?(:select)
            invalid = @value.select { |val| !@enum.include?(val) }

            if invalid.size > 0
              raise ArgumentError, "Setting #{@name} may only contain #{@enum.inspect}; the disallowed values #{invalid.inspect} were present"
            end
          else
            if !@enum.include?(@value)
              raise ArgumentError, "Setting #{@name} should be one of #{@enum.inspect}, not '#{@value}'"
            end
          end
        end
      end

      private

      def allowed_initialize_opts
        super.merge({:enum => true, :multi => true})
      end
    end
  end
end
