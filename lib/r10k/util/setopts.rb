module R10K
  module Util

    # Allow for easy setting of instance options based on a hash
    #
    # This emulates the behavior of Ruby 2.0 named arguments, but since r10k
    # supports Ruby 1.8.7+ we cannot use that functionality.
    module Setopts

      private

      # @param opts [Hash]
      # @param allowed [Hash<Symbol, Symbol>]
      #
      # @example
      #   opts = {:one => "one value"}
      #   allowed => {:one => :self}
      #   setopts(opts, allowed)
      #   @one # => "one value"
      #
      # @example
      #   opts = {:uno => "one value"}
      #   allowed => {:one => :one, :uno => :one}
      #   setopts(opts, allowed)
      #   @one # => "one value"
      #
      def setopts(opts, allowed)
        opts.each_pair do |key, value|
          if (ivar = allowed[key])
            ivar = key if ivar == :self
            instance_variable_set("@#{ivar}".to_sym, value)
          else
            raise ArgumentError, "#{self.class.name} cannot handle option '#{key}'"
          end
        end
      end
    end
  end
end
