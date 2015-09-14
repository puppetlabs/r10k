require 'spec_helper'

require 'r10k/action/deploy/module'

describe R10K::Action::Deploy::Module do

  subject { described_class.new({}, []) }

  it_behaves_like "a deploy action that can be write locked"
end
