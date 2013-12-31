require 'system/spec_helper'

describe 'printing the version' do
  describe command('r10k version') do
    it { should return_stdout /1.1/ }
  end
end
