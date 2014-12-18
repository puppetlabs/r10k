shared_examples_for "a subprocess runner" do |fixture_root|

  describe "running '/bin/echo test'" do
    subject { described_class.new(%w[/bin/echo test]) }

    it "sets the exit code to 0" do
      result = subject.run
      expect(result.exit_code).to eq 0
    end

    it "returns the contents of stdout" do
      result = subject.run
      expect(result.stdout).to eq 'test'
    end

    it "indicates the command succeeded" do
      result = subject.run
      expect(result).to be_success
      expect(result).to_not be_failed
    end
  end

  describe "running '/bin/ls' with a different working directory" do
    subject do
      described_class.new(%w[/bin/ls]).tap do |o|
        o.cwd = fixture_root
      end
    end

    it "returns the contents of the given working directory" do
      result = subject.run
      expect(result.stdout).to eq 'no-execute.sh'
    end
  end

  describe "running '/bin/false'" do
    subject { described_class.new(%w[/bin/false]) }

    it "sets the exit code to 1" do
      result = subject.run
      expect(result.exit_code).to eq 1
    end

    it "indicates the command failed" do
      result = subject.run
      expect(result).to_not be_success
      expect(result).to be_failed
    end
  end

  describe "running '/this/command/will/not/exist'" do
    subject { described_class.new(%w[/this/command/will/not/exist]) }

    it "indicates the command failed" do
      result = subject.run
      expect(result).to_not be_success
      expect(result).to be_failed
    end
  end

  describe "running a non-executable file", :unless => R10K::Util::Platform.windows? do
    let(:fixture_file) { File.join(fixture_root, 'no-execute.sh') }
    subject { described_class.new([fixture_file]) }

    it "indicates the command failed" do
      result = subject.run
      expect(result).to_not be_success
      expect(result).to be_failed
    end
  end
end
