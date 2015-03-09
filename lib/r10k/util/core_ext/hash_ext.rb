require 'r10k/util/symbolize_keys'

module R10K
  module Util
    module CoreExt
      module HashExt

        # @deprecated
        # @see {R10K::Util::SymbolizeKeys}
        module SymbolizeKeys
          def symbolize_keys!
            R10K::Util::SymbolizeKeys.symbolize_keys!(self)
          end
        end
      end
    end
  end
end
