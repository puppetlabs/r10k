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

      # @!attribute [rw] validate
      #   @return [Proc] An optional proc that will be called before storing a
      #     new setting value. This proc should raise an exception if the new
      #     value is not valid.
      attr_reader :validate

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
          @default.is_a?(Proc) ? @default.call : @default
        else
          @value
        end
      end

      # Assign a value to this setting.
      #
      # If a validate hook has been assigned, that will be invoked before the
      # setting is stored.
      #
      # @param newvalue [Object] The new setting to apply
      #
      # @return [void]
      def set(newvalue)
        if @validate
          @validate.call(newvalue)
        end
        @value = newvalue
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
        }
      end
    end
  end
end
