require 'r10k/settings/helpers'
require 'r10k/settings/collection'
require 'r10k/errors'
require 'r10k/util/setopts'

module R10K
  module Settings

    # A container for an arbitrarily long list of other settings.
    class List
      include R10K::Settings::Helpers
      include R10K::Util::Setopts

      # @!attribute [r] name
      #   @return [String] The name of this collection
      attr_reader :name

      # @param name [Symbol] The name of the setting for this definition.
      # @param item_proc [#call] An object whose #call method will return a
      #   new instance of another R10K::Settings class to hold each item
      #   added to this list.
      # @param opts [Hash] Additional options for this definition to control
      #   validation, normalization, and the like.
      #
      # @options opts [String] :desc Extended description of this setting.
      # @options opts [Array] :default Initial/default contents of the list.
      def initialize(name, item_proc, opts = {})
        @name = name
        @item_proc = item_proc
        @items = []

        setopts(opts, allowed_initialize_opts)
      end

      # Takes an array of key/value pairs and assigns each into a
      # new instance created by invoking @item_proc.
      #
      # @param items [Array] List of items to add to this list.
      def assign(items)
        return if items.nil?

        items.each do |values|
          new_item = @item_proc.call
          new_item.parent = self
          new_item.assign(values)
          @items << new_item
        end
      end

      # Validate all items in the list and return validation errors
      #
      # @return [nil, Hash] If all validation passed nil will be returned; if
      #   validation failed then a hash of those errors will be returned.
      def validate
        errors = {}

        @items.each_with_index do |item, idx|
          begin
            item.validate
          rescue => error
            errors[idx+1] = error
          end
        end

        if !errors.empty?
          raise ValidationError.new("Validation failed for '#{@name}' settings list", :errors => errors)
        end
      end

      # Evaluate all items in the list and return a frozen array of the final values.
      # @return [Array]
      def resolve
        @items.collect { |item| item.resolve }.freeze
      end

      class ValidationError < R10K::Error
        attr_reader :errors

        def initialize(mesg, options = {})
          super
          @errors = options[:errors]
        end

        def format
          struct = []
          struct << "#{message}:"
          @errors.each do |item, error|
            struct << indent(structure_exception("Item #{item}", error))
          end
          struct.join("\n")
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
        }
      end
    end
  end
end
