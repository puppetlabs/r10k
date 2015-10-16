require 'r10k/environment'

class R10K::Environment::Mock < R10K::Environment::Base
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
