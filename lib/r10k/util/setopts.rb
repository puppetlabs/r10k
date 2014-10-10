module R10K
  module Util

    # Allow for easy setting of instance options based on a hash
    #
    # This emulates the behavior of Ruby 2.0 named arguments, but since r10k
    # supports Ruby 1.8.7+ we cannot use that functionality.
    module Setopts

      private

      def setopts(opts, allowed)
        opts.each_pair do |key, value|
          if allowed.include?(key)
            instance_variable_set("@#{key}".to_sym, value)
          else
            raise ArgumentError, "#{self.class.name} cannot handle option '#{key}'"
          end
        end
      end
    end
  end
end
