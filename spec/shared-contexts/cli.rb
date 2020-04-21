shared_context 'cli' do
  def exit_with_code_and_message(r10k_args, code = 0, message = nil, out = 'stdout')
    expect do
      expect { r10k.run(r10k_args) }.to exit_with(code)
    end.to output(message).send("to_#{out}".to_sym)
  end

  def filtered_extra_args
    extra_args.reject { |arg| arg == '--' }
  end

  def string_to_module(str)
    str.split('::').inject(Object) { |o, c| o.const_get c }
  end

  def setup_mock_run(command)
    command.block = lambda do |opts, args, cmd|
      [opts, args.to_a, cmd]
    end
  end

  def setup_mock_runner(command, klass)
    command.block = lambda do |opts, args, cmd|
      klass.new(opts, args.to_a, cmd)
    end
  end
end
