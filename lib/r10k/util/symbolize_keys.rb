module R10K
  module Util
    module SymbolizeKeys
      module_function

      # Convert all String keys to Symbol keys
      #
      # @param hash [Hash] The data structure to convert
      # @param recurse [Boolean] Whether to recursively symbolize keys in nested
      #   hash values. Defaults to false.
      # @raise [TypeError] If a String key collides with an existing Symbol key
      # @return [void]
      def symbolize_keys!(hash, recurse = false)
        hash.keys.each do |key|
          if key.is_a?(String)
            if hash.key?(key.to_sym)
              raise TypeError, "An existing interned key for #{key} exists, cannot overwrite"
            end
            hash[key.to_sym] = hash.delete(key)
            key = key.to_sym
          end

          value = hash[key]
          if recurse
            if value.is_a?(Hash)
              symbolize_keys!(value, true)
            elsif value.is_a?(Array)
              value.map { |item| symbolize_keys!(item, true) if item.is_a?(Hash) }
            end
          end
        end
      end
    end
  end
end
