require 'spec_helper'
require 'r10k/source'
require 'json'
require 'yaml'

describe R10K::Source::Exec do

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

  describe 'initialize' do
    context 'with a valid command' do
      context 'that produces valid output' do
        it 'accepts json' do
          allow_any_instance_of(R10K::Util::Subprocess)
            .to receive(:execute)
            .and_return(double('result', stdout: environments_hash.to_json))

          source = described_class.new('execsource', '/some/nonexistent/dir', command: '/path/to/command')
          expect(source.environments.map(&:name)).to contain_exactly('production', 'development')
        end

        it 'accepts yaml' do
          allow_any_instance_of(R10K::Util::Subprocess)
            .to receive(:execute)
            .and_return(double('result', stdout: environments_hash.to_yaml))

          source = described_class.new('execsource', '/some/nonexistent/dir', command: '/path/to/command')
          expect(source.environments.map(&:name)).to contain_exactly('production', 'development')
        end

      end

      context 'that produces invalid output' do
        it 'raises an error for non-json, non-yaml data' do
          allow_any_instance_of(R10K::Util::Subprocess)
            .to receive(:execute)
            .and_return(double('result', stdout: "one:\ntwo\n"))

          source = described_class.new('execsource', '/some/nonexistent/dir', command: '/path/to/command')
          expect { source.environments }.to raise_error(/Error parsing command output/)
        end
      end
    end
  end
end
