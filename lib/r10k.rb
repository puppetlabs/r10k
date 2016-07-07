require 'gettext-setup'

module R10K
  GettextSetup.initialize(File.absolute_path('../locales', File.dirname(__FILE__)))

  # Attempt to set the R10k error and log message locale
  FastGettext.locale = ENV["LANG"]
end

require 'r10k/version'
require 'r10k/logging'
