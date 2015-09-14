require 'spec_helper'

require 'r10k/deployment'
require 'r10k/action/deploy/environment'

describe R10K::Action::Deploy::Environment do

  subject { described_class.new({}, []) }

  it_behaves_like "a deploy action that can be write locked"
end
