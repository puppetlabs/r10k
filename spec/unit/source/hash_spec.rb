require 'spec_helper'
require 'r10k/source'

describe R10K::Source::Hash do
  let(:environments_hash) do
    {
      'production' => {
        'remote'  => 'https://git.example.com/puppet/control-repo.git',
        'ref'     => 'release-141',
        'modules' => {
          'puppetlabs-stdlib' => '6.1.0',
          'puppetlabs-ntp' => '8.1.0',
          'example-myapp1' => {
            'git' => 'https://git.example.com/puppet/example-myapp1.git',
            'ref' => 'v1.3.0'
          }
        }
      },
      'development' => {
        'remote'  => 'https://git.example.com/puppet/control-repo.git',
        'ref'     => 'master',
        'modules' => {
          'puppetlabs-stdlib' => '6.1.0',
          'puppetlabs-ntp' => '8.1.0',
          'example-myapp1' => {
            'git' => 'https://git.example.com/puppet/example-myapp1.git',
            'ref' => 'v1.3.1'
          }
        }
      }
    }
  end

  describe "with a prefix" do
    subject do
      described_class.new('hashsource', '/some/nonexistent/dir',
                          prefix: 'prefixed', environments: environments_hash)
    end

    it "prepends environment names with a prefix" do
      environments = subject.environments
      expect(environments[0].dirname).to eq 'prefixed_production'
      expect(environments[1].dirname).to eq 'prefixed_development'
    end
  end
end
