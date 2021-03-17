require 'spec_helper'
require 'r10k/source'

describe R10K::Source::Yaml do

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

  describe "with valid yaml file" do
    it "produces environments" do
      allow(YAML).to receive(:load_file).with('/envs.yaml').and_return(environments_hash)
      source = described_class.new('yamlsource', '/some/nonexistent/dir', config: '/envs.yaml')
      expect(source.environments.map(&:name)).to contain_exactly('production', 'development')
    end
  end
end
