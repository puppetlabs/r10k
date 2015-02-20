require 'r10k/util/commands'
require 'r10k/util/exec_env'

require 'tmpdir'

describe R10K::Util::Commands do
  describe "#which" do

    before do
      allow(File).to receive(:executable?).and_return false
      allow(File).to receive(:file?).and_return false
    end

    def stub_executable(exe)
      allow(File).to receive(:executable?).with(exe).and_return true
      allow(File).to receive(:file?).with(exe).and_return true
    end

    describe "when ENV['PATHEXT'] is unset" do
      let(:path) { Dir.mktmpdir }

      around(:each) do |example|
        R10K::Util::ExecEnv.withenv('PATHEXT' => nil, 'PATH' => path) do
          example.run
        end
      end

      it "returns the first matching command in PATH" do
        exe = File.join(path, 'git')
        stub_executable(exe)
        expect(described_class.which("git")).to eq exe
      end

      it "returns nil if the command could not be found" do
        exe = File.join(path, 'git')
        expect(described_class.which("git")).to be_nil
      end
    end

    describe "when ENV['PATHEXT'] is set" do
      let(:path) { Dir.mktmpdir }

      around(:each) do |example|
        R10K::Util::ExecEnv.withenv('PATHEXT' => '.bat;.exe;.cmd', 'PATH' => path) do
          example.run
        end
      end

      it "returns the first matching command in PATH" do
        exe = File.join(path, 'git.exe')
        stub_executable(exe)
        expect(described_class.which("git")).to eq exe
      end

      it "returns nil if the command could not be found" do
        exe = File.join(path, 'git.exe')
        expect(described_class.which("git")).to be_nil
      end
    end
  end
end
