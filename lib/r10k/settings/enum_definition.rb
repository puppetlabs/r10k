require 'r10k/settings/definition'

module R10K
  module Settings
    class EnumDefinition < R10K::Settings::Definition

      def validate
        if @value
          if @multi && @value.respond_to?(:select)
            invalid = @value.select { |val| !@enum.include?(val) }

            if invalid.size > 0
              raise ArgumentError, _("Setting %{name} may only contain %{enums}; the disallowed values %{invalid} were present") % {name: @name, enums: @enum.inspect, invalid: invalid.inspect}
            end
          else
            if !@enum.include?(@value)
              raise ArgumentError, _("Setting %{name} should be one of %{enums}, not '%{value}'") % {name: @name, enums: @enum.inspect, value: @value}
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
