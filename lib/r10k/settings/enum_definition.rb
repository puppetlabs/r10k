require 'r10k/settings/definition'

module R10K
  module Settings
    # Define a setting with a list of valid values.
    #
    # @example
    #   defn = R10K::Settings::EnumDefinition.new(:list, :enum => ['one', 'two', 'three'])
    #   defn.set('two') #=> nil
    #   defn.set(:invalid) #=> ArgumentError, "Definition list expects one of ['one', 'two', 'three'], got :invalid"
    class EnumDefinition < R10K::Settings::Definition

      # @!attribute [r] enum
      #   @return [Array] A list of valid values for this definition.
      attr_reader :enum

      def set(newvalue)
        if !enum.include?(newvalue)
          raise ArgumentError, "Definition #{@name} expects one of #{enum.inspect}, got #{newvalue.inspect}"
        end
        super
      end

      private

      def allowed_initialize_opts
        super.merge(:enum => true)
      end
    end
  end
end
