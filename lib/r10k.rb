module R10K
  begin
    # requires the `documentation` gem group
    require 'gettext-setup'
    GettextSetup.initialize(File.absolute_path('../locales', File.dirname(__FILE__)))
  rescue LoadError
  end

  require 'fast_gettext'
  require 'locale'
  class ::Object
    include FastGettext::Translation
  end
  # Attempt to set the R10k error and log message locale
  FastGettext.locale = ENV["LANG"]
end

require 'r10k/version'
require 'r10k/logging'
