module R10K
  module Util

    # Allow for easy setting of instance options based on a hash
    #
    # This emulates the behavior of Ruby 2.0 named arguments, but since r10k
    # supports Ruby 1.8.7+ we cannot use that functionality.
    module Setopts

      class Ignore; end

      include R10K::Logging

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
      def setopts(opts, allowed, raise_on_unhandled: true)
        processed_vars = {}
        opts.each_pair do |key, value|
          if allowed.key?(key)
            # Ignore nil options and explicit ignore param
            next unless rhs = allowed[key]
            next if rhs == ::R10K::Util::Setopts::Ignore

            var = case rhs
                  when :self, TrueClass
                    # tr here is because instance variables cannot have hyphens in their names.
                    "@#{key}".tr('-','_').to_sym
                  else
                    # tr here same as previous
                    "@#{rhs}".tr('-','_').to_sym
                  end

            if processed_vars.include?(var)
              # This should be a raise, but that would be a behavior change and
              # should happen on a SemVer boundry.
              logger.warn _("%{class_name} parameters '%{a}' and '%{b}' conflict. Specify one or the other, but not both" \
                            % {class_name: self.class.name, a: processed_vars[var], b: key})
            end

            instance_variable_set(var, value)
            processed_vars[var] = key
          else
            err_str = _("%{class_name} cannot handle option '%{key}'") % {class_name: self.class.name, key: key}
            if raise_on_unhandled
              raise ArgumentError, err_str
            else
              logger.warn(err_str)
            end
          end
        end
      end
    end
  end
end
