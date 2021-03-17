module R10K
  module Environment
    # Handle environment name validation and modification.
    #
    # @api private
    class Name

      # @!attribute [r] name
      #   @return [String] The unmodified name of the environment
      attr_reader :name

      INVALID_CHARACTERS = %r[\W]

      def initialize(name, opts)
        @source  = opts[:source]
        @prefix  = opts[:prefix]
        @invalid = opts[:invalid]

        @name = derive_name(name, opts[:strip_component])
        @opts = opts

        case @invalid
        when 'correct_and_warn'
          @validate = true
          @correct  = true
        when 'correct'
          @validate = false
          @correct  = true
        when 'error'
          @validate = true
          @correct  = false
        when NilClass
          @validate = opts[:validate]
          @correct = opts[:correct]
        end
      end

      # Should the environment name have invalid characters removed?
      def correct?
        @correct
      end

      def validate?
        @validate
      end

      def valid?
        if @validate
          ! @name.match(INVALID_CHARACTERS)
        else
          true
        end
      end

      # The directory name for the environment, modified as necessary to remove
      # invalid characters.
      #
      # @return [String]
      def dirname
        dir = @name.dup

        prefix = derive_prefix(@source,@prefix)

        if @correct
          dir.gsub!(INVALID_CHARACTERS, '_')
        end

        "#{prefix}#{dir}"
      end


      private

      def derive_name(name, strip_component)
        return name unless strip_component

        unless strip_component.is_a?(String)
          raise _('Improper configuration value given for strip_component setting in %{src} source. ' \
                  'Value must be a string, a /regex/, false, or omitted. Got "%{val}" (%{type})' \
                  % {src: @source, val: strip_component, type: strip_component.class})
        end

        if %r{^/.*/$}.match(strip_component)
          regex = Regexp.new(strip_component[1..-2])
          name.gsub(regex, '')
        elsif name.start_with?(strip_component)
          name[strip_component.size..-1]
        else
          name
        end
      end

      def derive_prefix(source,prefix)
        if prefix == true
          "#{source}_"
        elsif prefix.is_a? String
          "#{prefix}_"
        else
          nil
        end
      end
    end
  end
end
