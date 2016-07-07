require 'r10k/errors'
require 'r10k/features'

module R10K
  module Util
    module License
      extend R10K::Logging

      def self.load
        if R10K::Features.available?(:pe_license)
          logger.debug2 _("pe_license feature is available, loading PE license key")
          begin
            return PELicense.load_license_key
          rescue PELicense::InvalidLicenseError => e
            raise R10K::Error.wrap(e, _("Invalid PE license detected: %{error_msg}") % {error_msg: e.message} )
          end
        else
          logger.debug2 _("pe_license feature is not available, PE only Puppet modules will not be downloadable.")
          nil
        end
      end
    end
  end
end
