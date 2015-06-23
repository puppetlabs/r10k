require 'r10k/settings/definition'
require 'r10k/util/setopts'
require 'r10k/util/symbolize_keys'
require 'r10k/errors'

module R10K
  module Settings

    # Define a group of settings, which can be single definitions or nested
    # collections.
    class Collection

      # @!attribute [r] name
      #   @return [String] The name of this collection
      attr_reader :name

      # @param name [Symbol] The name of the collection
      # @param settings [Array] All settings in this collection
      def initialize(name, settings)
        @name = name
        @settings = Hash[settings.map { |s| [s.name, s] }]
      end

      # Assign new values, perform validation checks, and return the final
      # values for this collection
      def evaluate(newvalues)
        assign(newvalues)
        validate
        resolve
      end

      # Assign a hash of values to the settings in this collection.
      #
      # If the passed hash contains any invalid settings values, the names
      # of those settings are stored for use in the {#validate} method.
      #
      # @param newvalues [Hash]
      # @return [void]
      def assign(newvalues)
        R10K::Util::SymbolizeKeys.symbolize_keys!(newvalues)
        @settings.each_pair do |name, setting|
          if newvalues.key?(name)
            setting.assign(newvalues[name])
          end
        end
      end

      # Validate all settings and return validation errors
      #
      # @return [nil, Hash] If all validation passed nil will be returned; if
      #   validation failed then a hash of those errors will be returned.
      def validate
        errors = {}

        @settings.each_pair do |name, setting|
          begin
            setting.validate
          rescue => error
            errors[name] = error
          end
        end

        if !errors.empty?
          raise ValidationError.new("Validation failures for #{@name}", :errors => errors)
        end
      end

      # Evaluate all settings and return a frozen hash of the final values.
      # @return [Hash]
      def resolve
        rv = {}
        @settings.each_pair do |name, setting|
          rv[name] = setting.resolve
        end
        rv.freeze
      end

      class ValidationError < R10K::Error

        attr_reader :errors

        def initialize(mesg, options = {})
          super
          @errors = options[:errors]
        end
      end
    end
  end
end
