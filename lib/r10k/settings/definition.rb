require 'r10k/settings/helpers'
require 'r10k/util/setopts'

module R10K
  module Settings

    # Define a single setting and additional attributes like descriptions,
    # default values, and validation.
    class Definition
      require 'r10k/settings/uri_definition'
      require 'r10k/settings/enum_definition'

      include R10K::Settings::Helpers
      include R10K::Util::Setopts

      # @!attribute [r] name
      #   @return [String] The name of this setting
      attr_reader :name

      # @!attribute [r] value
      #   @return [Object] An explicitly set value. This should only be used if
      #     an optional default value should not be used; otherwise use {#resolve}.
      attr_reader :value

      # @!attribute [r] desc
      #   @return [String] An optional documentation string for this setting.
      attr_reader :desc

      # @param name [Symbol] The name of the setting for this definition.
      # @param opts [Hash] Additional options for this definition to control
      #   validation, normalization, and the like.
      #
      # @option opts [Proc, Object] :default An optional proc or object for
      #   this setting. If no value has been set and the default is a Proc then
      #   it will be called and the result will be returned, otherwise if the
      #   value is not set the default value itself is returned.
      #
      # @options opts [Proc] :validate An optional proc that can be used to
      #   validate an assigned value. Default values are not assigned.
      #
      # @options opts [Proc] :normalize An optional proc that can be used to
      #   normalize an explicitly assigned value.
      def initialize(name, opts = {})
        @name = name
        setopts(opts, allowed_initialize_opts)
      end

      # Assign new values, perform validation checks, and return the final
      # values for this collection
      def evaluate(newvalue)
        assign(newvalue)
        validate
        resolve
      end

      # Store an explicit value for this definition
      #
      # If a :normalize hook has been given then it will be called with the
      # new value and the returned value will be stored.
      #
      # @param newvalue [Object] The value to store for this setting
      # @return [void]
      def assign(newvalue)
        if @normalize
          @value = @normalize.call(newvalue)
        else
          @value = newvalue
        end
      end

      # Call any validation hooks for this definition.
      #
      # The :validate hook will be called if the hook has been set and an
      # explicit value has been assigned to this definition. Validation
      # failures should be indicated by the :validate hook raising an exception.
      #
      # @raise [Exception] An exception class indicating that validation failed.
      # @return [nil]
      def validate
        if @value && @validate
          @validate.call(@value)
        end
        nil
      end

      # Compute the final value of this setting. If a value has not been
      # assigned the default value will be used.
      #
      # @return [Object] The final value of this definition.
      def resolve
        if !@value.nil?
          @value
        elsif @default
          if @default == :inherit
            # walk all the way up to root, starting with grandparent
            ancestor = parent

            while ancestor = ancestor.parent
              return ancestor[@name].resolve if ancestor.respond_to?(:[]) && ancestor[@name]
            end
          elsif @default.is_a?(Proc)
            @default.call
          else
            @default
          end
        end
      end

      private

      # Subclasses may define additional params that are accepted at
      # initialization; they should override this method to add any
      # additional fields that should be respected.
      def allowed_initialize_opts
        {
          :desc      => true,
          :default   => true,
          :validate  => true,
          :normalize => true,
        }
      end
    end
  end
end
