shared_examples 'missing argument' do |option, optinfo|
  it 'prints error and exits 1' do
    ["--#{option}", optinfo[:short]].compact.each do |opt|
      exit_with_code_and_message(command_args + [opt] + extra_args, 1, %r{option requires an argument}, 'stderr')
    end
  end
end

shared_examples 'accepts option' do |option, optinfo, value|
  it 'accepts the option' do
    ["--#{option}", optinfo[:short]].compact.each do |opt|
      expect(r10k.run(command_args + [opt, value].compact + extra_args)).to eq([{ option.to_sym => value || true }, filtered_extra_args, command])
    end
  end
end

shared_examples 'help option' do |option, optinfo|
  context "when #{option} specified" do
    it 'prints command help and exits 0' do
      ["--#{option}", optinfo[:short]].compact.each do |help_arg|
        expect(command).to receive(:help).and_call_original
        exit_with_code_and_message(command_args + [help_arg] + extra_args, 0, %r{USAGE\s*r10k #{command_args.join(' ')}})
      end
    end
  end
end

shared_examples 'Cri argument parsing' do |options, include_parent_examples|
  context 'Cri argument parsing' do
    let!(:prev_run) { command.block }

    before(:each) do
      setup_mock_run(command)
    end

    after(:each) do
      command.block = prev_run
    end

    options.each do |option, optinfo|
      if optinfo[:custom_cri_examples]
        optinfo[:custom_cri_examples].each do |examples|
          include_examples examples, option, optinfo
        end
        next
      end

      case optinfo[:type]
      when :required
        context "when #{option} specified without an argument" do
          include_examples 'missing argument', option, optinfo
        end

        context "when #{option} specified with an argument" do
          include_examples 'accepts option', option, optinfo, optinfo[:value]
        end
      when :optional
        context "when #{option} specified without an argument" do
          include_examples 'accepts option', option, optinfo, nil
        end

        context "when #{option} specified with an argument" do
          include_examples 'accepts option', option, optinfo, optinfo[:value]
        end
      when :flag
        context "when #{option} specified" do
          include_examples 'accepts option', option, optinfo, nil
        end
      else
        raise ArgumentError, "Unknown option type #{optinfo} for #{option}"
      end
    end

    include_examples 'parent command examples' if include_parent_examples
  end
end

shared_examples 'parent command examples' do
  context 'with no arguments' do
    it 'prints command help and exits 0' do
      command.block = prev_run
      expect(command).to receive(:help).and_call_original
      exit_with_code_and_message(command_args, 0, %r{USAGE\s*r10k #{command_args.join(' ')}})
    end
  end

  context 'with unknown argument' do
    let(:command_args) { super() + ['invalid_arg'] }

    it 'prints error to stderr and exits 1' do
      exit_with_code_and_message(command_args, 1, %r{unknown command 'invalid_arg'}, 'stderr')
    end
  end
end

shared_examples 'Action argument parsing' do |options|
  context 'Action argument parsing' do
    def instance(opts = [])
      r10k.run(command_args + opts.compact + extra_args).instance_variable_get(:@runner).instance
    end

    context 'CriRunner' do
      it do
        expect(r10k.run(command_args + extra_args)).to be_an_instance_of(R10K::Action::CriRunner)
      end
    end

    context 'Runner' do
      it do
        expect(r10k.run(command_args + extra_args).instance_variable_get(:@runner)).to be_an_instance_of(R10K::Action::Runner)
      end
    end

    context 'Action' do
      it do
        expect(instance).to be_an_instance_of(action_class)
      end
    end

    options.each do |option, optinfo|
      if optinfo[:custom_action_examples]
        optinfo[:custom_action_examples].each do |examples|
          include_examples examples, option, optinfo
        end
        next
      end

      context "when #{option} specified" do
        let(:option_variable) do
          "@#{option.to_s.sub(%r{^-*}, '')}".tr('-', '_').to_sym
        end

        if CRI_RUNNER_OPTIONS.include? option
          it 'CriRunner processes the option' do
            ["--#{option}", optinfo[:short]].compact.each do |opt|
              expect(instance([opt, optinfo[:value]]).instance_variable_defined?(option_variable)).to be false
            end
          end
        else
          it 'has the option set' do
            ["--#{option}", optinfo[:short]].compact.each do |opt|
              expect(instance([opt, optinfo[:value]]).instance_variable_get(option_variable)).to eq(optinfo[:value] || true)
            end
          end
        end
        it 'processes extra args correctly' do
          ["--#{option}", optinfo[:short]].compact.each do |opt|
            expect(instance([opt, optinfo[:value]]).instance_variable_get(:@argv)).to eq(filtered_extra_args)
          end
        end
      end
    end

    context 'when no options specified' do
      it 'processes extra args correctly' do
        expect(instance.instance_variable_get(:@argv)).to eq(filtered_extra_args)
      end
    end
  end
end

shared_examples 'deploy examples' do
  before(:each) do
    allow(File).to receive(:executable?).with('/path/to/puppet').and_return('true')
  end
end

shared_examples 'version examples' do
  context 'with no arguments' do
    it 'prints r10k version' do
      exit_with_code_and_message(command_args, 0, "r10k #{R10K::VERSION}\n")
    end
  end

  context 'with -v or --verbose' do
    it 'prints verbose version info' do
      ['-v', '--verbose'].each do |option|
        exit_with_code_and_message(command_args + [option], 0, %r{r10k #{Regexp.quote(R10K::VERSION)}\n#{Regexp.quote(RUBY_DESCRIPTION)}})
      end
    end
  end
end
