require 'tempfile'

module RSpecSystem
  module Puppetfile
    def puppetfile_install(options = {})
      expected_exit_code = options.fetch(:exit_code, 0)

      shell %[r10k puppetfile install] do |results|
        expect(results.exit_code).to eq expected_exit_code
      end
    end

    def create_puppetfile(*mods)
      tmp = Tempfile.new('rs-r10k-puppetfile')
      tmp.write(mods.join("\n"))
      tmp.flush
      rcp :sp => tmp.path, :dp => "Puppetfile"
    end
  end
end

RSpec.configure do |config|
  config.include RSpecSystem::Puppetfile
end
