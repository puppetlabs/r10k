require 'r10k/environment'
require 'r10k/util/purgeable'

class R10K::Environment::Mock < R10K::Environment::Base
  include R10K::Util::Purgeable

  def sync
    "synced"
  end

  def status
    :insync
  end

  def signature
    "mock"
  end
end
