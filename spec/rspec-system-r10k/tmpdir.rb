# Create and teardown a tmpdir around rspec example groups.

module RSpecSystem
  module Tmpdir
    def tmpdir
      dir = RSpec.configuration.tmpdir_stack.last
      if dir.nil?
        raise ArgumentError, "No tmpdir currently defined"
      else
        dir
      end
    end
  end
end

RSpec.configure do |config|

  config.add_setting(:tmpdir_stack, :default => [])

  config.include RSpecSystem::Tmpdir
  config.extend RSpecSystem::Tmpdir

  config.before(:all, :rs_tmpdir => true) do |example|
    shell 'mktemp -p $PWD -d rs.XXXXXXXX' do |sh|
      RSpec.configuration.tmpdir_stack.push sh.stdout.chomp
    end
  end

  config.after(:all, :rs_tmpdir => true) do |example|
    RSpec.configuration.tmpdir_stack.pop
  end
end
