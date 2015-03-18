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
        @name   = name
        @opts   = opts

        @source  = opts[:source]
        @prefix  = opts[:prefix]
        @invalid = opts[:invalid]

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

        if @prefix
          dir = "#{@source}_#{dir}"
        end

        if @correct
          dir.gsub!(INVALID_CHARACTERS, '_')
        end

        dir
      end
    end
  end
end
