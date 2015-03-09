require 'spec_helper'
require 'r10k/git'

describe R10K::Git do
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
  end
end
