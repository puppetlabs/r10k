module R10K
  module Util
    module CoreExt
      module HashExt
        module SymbolizeKeys
          def symbolize_keys!
            self.keys.each do |key|
              next unless key.is_a? String
              if self[key.to_sym]
                raise TypeError, "An existing interned key for #{key} exists, cannot overwrite"
              end
              self[key.to_sym] = self.delete(key)
            end
          end
        end
      end
    end
  end
end
