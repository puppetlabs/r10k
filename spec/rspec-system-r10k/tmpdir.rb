# Create and teardown a tmpdir around rspec example groups.

module RSpecSystem
  module Tmpdir
    def tmpdir
      RSpec.configuration.tmpdir
    end

    def tmpdir=(x)
      RSpec.configuration.tmpdir = x
    end
  end
end

RSpec.configure do |config|

  config.add_setting(:tmpdir, :default => nil)

  config.include RSpecSystem::Tmpdir
  config.extend RSpecSystem::Tmpdir

  config.before(:all, :rs_tmpdir => true) do |example|
    shell 'mktemp -p $PWD -d rs.XXXXXXXX' do |sh|
      RSpec.configuration.tmpdir = sh.stdout.chomp
    end
  end


  config.after(:all, :rs_tmpdir => true) do |example|
    RSpec.configuration.tmpdir = nil
  end
end
