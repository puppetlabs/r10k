# frozen_string_literal: true

require 'spec_helper'
require 'r10k/cli'

# Command options that are processed by R10K::Action::CriRunner
CRI_RUNNER_OPTIONS = %i[color verbose].freeze

COMMANDS = {
  r10k: {
    options: {
      config: { type: :required, value: '/path/to/config', short: '-c' },
      color: { type: :flag },
      help: { type: :flag, short: '-h', custom_cri_examples: ['help option'], custom_action_examples: [] },
      trace: { type: :flag, short: '-t' },
      verbose: { type: :optional, value: 'debug', short: '-v' },
    },
    subcommands: {
      deploy: {
        options: {},
        subcommands: {
          display: {
            options: {
              detail: { type: :flag },
              fetch: { type: :flag },
              format: { type: :required, value: 'yaml' },
              puppetfile: { type: :flag, short: '-p' },
            },
          },
          environment: {
            options: {
              cachedir: { type: :required, value: '/path/to/cachedir' },
              'default-branch-override': { type: :required, value: 'branch-override' },
              'generate-types': { type: :flag },
              'no-force': { type: :flag },
              'puppet-path': { type: :required, value: '/path/to/puppet' },
              puppetfile: { type: :flag, short: '-p' },
            },
            extra_args: {
              'environments' => %w[environment1 environment2],
            },
            included_examples: ['deploy examples'],
          },
          module: {
            options: {
              cachedir: { type: :required, value: '/path/to/cachedir' },
              environment: { type: :required, value: 'environment1', short: '-e' },
              'generate-types': { type: :flag },
              'no-force': { type: :flag },
              'puppet-path': { type: :required, value: '/path/to/puppet' },
            },
            extra_args: {
              'modules' => %w[module1 module2],
            },
            included_examples: ['deploy examples'],
          },
        },
      },
      help: {
        options: {
          verbose: { type: :flag, short: '-v' },
        },
        no_runner: true,
        command: R10K::CLI.command.command_named('help'),
      },
      puppetfile: {
        options: {},
        subcommands: {
          check: {
            options: {
              puppetfile: { type: :required, value: '/path/to/Puppetfile' },
            },
          },
          install: {
            options: {
              moduledir: { type: :required, value: '/path/to/moduledir' },
              puppetfile: { type: :required, value: '/path/to/Puppetfile' },
              force: { type: :flag },
            },
          },
          purge: {
            options: {
              moduledir: { type: :required, value: '/path/to/moduledir' },
              puppetfile: { type: :required, value: '/path/to/Puppetfile' },
            },
          },
        },
      },
      version: {
        options: {},
        no_runner: true,
        included_examples: ['version examples'],
      },
    },
  },
}.freeze

def add_commands(commands, parents = [])
  commands.each do |cmd, cmdinfo|
    args = parents + [cmd]
    subargs = (parents + [cmd]).reject { |p| p == :r10k }
    subargs_module_string = ([''] + subargs).map { |p| p.to_s.capitalize }.join('::')

    # Collect options from parent commands
    options = {}
    args.each_index do |i|
      keys = args.slice(0, i + 1).zip([:subcommands] * i).flatten.compact + [:options]
      options.merge!(COMMANDS.dig(*keys))
    end

    context args.join(' ') do
      let!(:command)     { cmdinfo[:command] || string_to_module("R10K::CLI#{subargs_module_string}").command }
      let!(:prev_runner) { command.block }

      let(:command_args) { subargs.map(&:to_s) }
      let(:extra_args)   { [] }
      let(:action_class) { string_to_module("R10K::Action#{subargs_module_string}") }

      (cmdinfo[:included_examples] || []).each do |examples|
        include_examples examples
      end

      if cmdinfo[:extra_args]
        cmdinfo[:extra_args].each do |desc, extra_args|
          context "without #{desc} specified" do
            add_includes(cmdinfo, options)
          end

          context "with #{desc} specified" do
            let(:extra_args) { ['--'] + extra_args }

            add_includes(cmdinfo, options)
          end
        end
      else
        add_includes(cmdinfo, options)
      end
    end

    add_commands(cmdinfo[:subcommands], parents + [cmd]) if cmdinfo[:subcommands]
  end
end

def add_includes(cmdinfo, options)
  include_examples 'Cri argument parsing', options, cmdinfo[:subcommands] ? true : false

  return if cmdinfo[:subcommands] || cmdinfo[:no_runner]

  before(:each) do
    setup_mock_runner(command, R10K::Action::CriRunner.wrap(action_class))
  end

  after(:each) do
    command.block = prev_runner
  end

  include_examples 'Action argument parsing', options
end

def check_command(command, parents = [])
  command_key = parents.zip([:subcommands] * parents.size).flatten.compact + [command.name.to_sym]
  subcommands = COMMANDS.dig(*command_key, :subcommands) || {}
  options = COMMANDS.dig(*command_key, :options)

  context "command #{(parents + [command.name]).join(' ')}" do
    it 'command and option checks exist' do
      expect(options).to be_an_instance_of(Hash), "No `#{command.name}: { options: {...} }` definition found in COMMANDS"
      expect(command.option_definitions.map(&:long).sort).to eq(options.keys.map(&:to_s).sort)
    end
  end

  command.commands.each do |cmd|
    check_command(cmd, parents + [command.name.to_sym])
  end
end

describe R10K::CLI do
  subject(:r10k) { described_class.command }

  include_context 'cli'

  # r10k has many methods with `exit`, which cause rspec to immediately exit if not caught
  # Tests should also not print to stdout or stderr unexpectedly
  around(:each) do |example|
    expect do
      expect do
        expect { example.run }.not_to output.to_stderr
      end.not_to output.to_stdout
    end.not_to raise_error
  end

  # Generate examples for each command defined in COMMANDS
  add_commands(COMMANDS)

  # Ensure each command and command option defined in r10k is defined in COMMANDS
  context 'when checking all commands and options have checks' do
    check_command(described_class.command)
  end
end
