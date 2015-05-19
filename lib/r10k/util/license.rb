require 'r10k/errors'
require 'rubygems'

module R10K
  module Util
    module License
      def self.load
        if Gem::Specification::find_all_by_name('pe-license').any?
          begin
            return PELicense.load_license_key
          rescue PELicense::InvalidLicenseError => e
            raise R10K::Error.wrap(e, "Invalid PE license detected: #{e.message}")
          end
        end

        nil
      end
    end
  end
end
