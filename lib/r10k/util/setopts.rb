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
      # @example
      #
      #   opts = {:trace => "something"}
      #   allowed = {:trace => nil}
      #   setopts(opts, allowed)
      #   @trace # => nil
      #
      def setopts(opts, allowed)
        opts.each_pair do |key, value|
          if allowed.key?(key)
            rhs = allowed[key]
            case rhs
            when NilClass, FalseClass
              # Ignore nil options
            when :self, TrueClass
              instance_variable_set("@#{key}".to_sym, value)
            else
              instance_variable_set("@#{rhs}".to_sym, value)
            end
          else
            raise ArgumentError, "#{self.class.name} cannot handle option '#{key}'"
          end
        end
      end
    end
  end
end
