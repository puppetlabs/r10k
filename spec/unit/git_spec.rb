require 'spec_helper'
require 'r10k/git'

describe R10K::Git do
  before { described_class.reset! }
  after  { described_class.reset! }

  describe 'selecting the default provider' do
    it 'returns shellgit when the git executable is present' do
      expect(R10K::Features).to receive(:available?).with(:shellgit).and_return true
      expect(described_class.default).to eq R10K::Git::ShellGit
    end

    it 'returns rugged when the git executable is absent and the rugged library is present' do
      expect(R10K::Features).to receive(:available?).with(:shellgit).and_return false
      expect(R10K::Features).to receive(:available?).with(:rugged).and_return true
      expect(described_class.default).to eq R10K::Git::Rugged
    end

    it 'raises an error when the git executable and rugged library are absent' do
      expect(R10K::Features).to receive(:available?).with(:shellgit).and_return false
      expect(R10K::Features).to receive(:available?).with(:rugged).and_return false
      expect {
        described_class.default
      }.to raise_error(R10K::Error, 'No Git providers are functional.')
    end

    it "goes into an error state if an invalid provider was set" do
      begin
        described_class.provider = :nope
      rescue R10K::Error
      end

      expect {
        described_class.provider
      }.to raise_error(R10K::Error, "No Git provider set.")
    end
  end

  describe 'explicitly setting the provider' do
    it "raises an error if the provider doesn't exist" do
      expect {
        described_class.provider = :nope
      }.to raise_error(R10K::Error, "No Git provider named 'nope'.")
    end

    it "raises an error if the provider isn't functional" do
      expect(R10K::Features).to receive(:available?).with(:shellgit).and_return false
      expect {
        described_class.provider = :shellgit
      }.to raise_error(R10K::Error, "Git provider 'shellgit' is not functional.")
    end

    it "sets the current provider if the provider exists and is functional" do
      expect(R10K::Features).to receive(:available?).with(:rugged).and_return true
      described_class.provider = :rugged
      expect(described_class.provider).to eq(R10K::Git::Rugged)
    end
  end

  describe "retrieving the current provider" do
    it "uses the default if a provider has not been set" do
      expect(described_class).to receive(:default).and_return :def
      expect(described_class.provider).to eq :def
    end

    it "uses an explicitly set provider" do
      expect(R10K::Features).to receive(:available?).with(:rugged).and_return true
      described_class.provider = :rugged
      expect(described_class).to_not receive(:default)
      expect(described_class.provider).to eq R10K::Git::Rugged
    end
  end
end
