require 'r10k/environment'

class R10K::Environment::Mock < R10K::Environment::Base
  def sync
    "synced"
  end
end
