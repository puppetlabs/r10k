require 'r10k/util/setopts'

module R10K
  module Settings

    # Define a single setting and additional attributes like descriptions,
    # default values, and validation.
    #
    # @example A basic setting with documentation
    #   defn = R10K::Settings::Definition.new(:basic, :desc => "Documentation for a simple setting")
    #   defn.get #=> nil
    #   defn.set(:myval)
    #   defn.get #=> :myval
    #
    # @example Specifying a default value
    #   defn = R10K::Settings::Definition.new(:defaultvalue, :default => :somedefault)
    #   defn.get #=> :somedefault
    #   defn.set(:myval)
    #   defn.get #=> :myval
    #
    # @example Specifying a default lambda
    #   defn = R10K::Settings::Definition.new(:defaultlambda, :default => lambda { |defn| "The default value for #{defn.name} is 'hello'" }
    #   defn.get #=> "The default value for defaultlambda is 'hello'"
    #
    # @example Adding a validation hook
    #   validator = lambda do |newvalue|
    #     if !newvalue.is_a?(String)
    #       raise ArgumentError, "#{newvalue} isn't a string"
    #     end
    #   end
    #
    #   defn = R10K::Settings::Definition.new(:defaultlambda, :validate => validator)
    #   defn.set("a string") #=> nil
    #   defn.set(123) #=> ArgumentError
    #
    # @example Filtering an input
    #   filter = lambda { |input| input.to_sym }
    #   defn = R10K::Settings::Definition.new(:filtered, :filter => filter)
    #   defn.set("myvalue") #=> nil
    #   defn.get #=> myvalue:Symbol
    #
    # @example Using an apply hook
    #   apply = lambda { |value| $globalstate = value }
    #   defn = R10K::Settings::Definition.new(:globalstate, :apply => apply)
    #   defn.set(:hello)
    #   $globalstate #=> nil
    #   defn.apply
    #   $globalstate #=> :hello
    #
    class Definition

      require 'r10k/settings/enum_definition'
      require 'r10k/settings/path_definition'

      include R10K::Util::Setopts

      # @!attribute [r] name
      #   @return [String] The name of this setting
      attr_reader :name

      # @!attribute [r] value
      #   @return [Object] An explicitly set value. This should only be used if
      #     an optional default value should not be used; otherwise use {#set}.
      attr_reader :value

      # @!attribute [r] desc
      #   @return [String] An optional documentation string for this setting.
      attr_reader :desc

      # @!attribute [rw] default
      #   @return [Proc, Object] An optional proc or object for this setting.
      #     If no value has been set, the default will be called and the result
      #     returned if it's a proc, otherwise the default value will simply be
      #     returned.
      attr_reader :default

      # @!attribute [rw] filter
      #   @return [Proc] An optional proc that will be called to modify a new
      #     value before validation is called. This can be used to normalize
      #     inputs before validation.
      attr_reader :filter

      # @!attribute [rw] validate
      #   @return [Proc] An optional proc that will be called before storing a
      #     new setting value. This proc should raise an exception if the new
      #     value is not valid.
      attr_reader :validate

      # @!attribute [rw] apply
      #   @return [Proc] An optional proc that can be used to apply this setting
      #     to the system.
      attr_reader :apply

      # @!attribute [rw] collection
      #   @return [R10K::Settings::Collection] The settings collection that
      #     this definition belongs to.
      attr_accessor :collection

      # @param name [Symbol] The name of the setting for this definition.
      # @param opts [Hash]
      def initialize(name, opts = {})
        @name = name
        setopts(opts, allowed_initialize_opts)
      end

      # Get the value of this setting.
      #
      # If an explicit value has been set it will be returned; otherwise if a
      # default value has been set and is a proc it will be evaluated and the
      # result will be returned, otherwise the default will be returned.
      #
      # @return [Object] The manually set value if given, else the default value
      def get
        if @value.nil?
          @default.is_a?(Proc) ? @default.call(self) : @default
        else
          @value
        end
      end

      # Assign a value to this setting.
      #
      # If a filter hook has been assigned, the filter hook will be invoked
      # and the result of the filtering will be validated/stored.
      #
      # If a validate hook has been assigned, the validate hook will be invoked
      # before the setting is stored.
      #
      # @param newvalue [Object] The new setting to apply
      #
      # @return [void]
      def set(newvalue)
        if @filter
          newvalue = @filter.call(newvalue)
        end
        if @validate
          @validate.call(newvalue)
        end
        @value = newvalue
      end

      # Invoke the apply hook if one has been set on this definition.
      #
      # @return [void]
      def apply!
        if @apply
          @apply.call(value)
        end
      end

      private

      # Subclasses may define additional params that are accepted at
      # initialization; they should override this method to add any additional
      # fields that should be respected.
      def allowed_initialize_opts
        {
          :desc     => true,
          :default  => true,
          :validate => true,
          :filter   => true,
          :apply    => true,
        }
      end
    end
  end
end
