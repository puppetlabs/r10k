require 'spec_helper'
require 'r10k/util/purgeable'

RSpec.describe R10K::Util::Purgeable do
  let(:managed_directories) do
    [
      'spec/fixtures/unit/util/purgeable/managed_one',
      'spec/fixtures/unit/util/purgeable/managed_two',
    ]
  end

  let(:desired_contents) do
    [
      'spec/fixtures/unit/util/purgeable/managed_one/expected_1',
      'spec/fixtures/unit/util/purgeable/managed_two/expected_2',
      'spec/fixtures/unit/util/purgeable/managed_one/new_1',
      'spec/fixtures/unit/util/purgeable/managed_two/new_2',
    ]
  end

  let(:test_class) do
    Struct.new(:managed_directories, :desired_contents) do
      include R10K::Util::Purgeable
      include R10K::Logging
    end
  end

  subject { test_class.new(managed_directories, desired_contents) }

  describe '#current_contents' do
    it 'collects contents of all managed directories' do
      expect(subject.current_contents).to contain_exactly(/expected_1/, /expected_2/, /unmanaged_1/, /unmanaged_2/)
    end
  end

  describe '#pending_contents' do
    it 'collects desired_contents that do not yet exist' do
      expect(subject.pending_contents).to contain_exactly(/new_1/, /new_2/)
    end
  end

  describe '#stale_contents' do
    it 'collects current_contents that should not exist' do
      expect(subject.stale_contents).to contain_exactly(/unmanaged_1/, /unmanaged_2/)
    end
  end

  describe '#purge!' do
    it 'does nothing when there is no stale_contents' do
      allow(subject).to receive(:stale_contents).and_return([])

      expect(FileUtils).to_not receive(:rm_rf)

      subject.purge!
    end

    it 'recursively deletes all stale_contents' do
      subject.stale_contents.each do |stale|
        expect(FileUtils).to receive(:rm_rf).with(stale, hash_including(secure: true))
      end

      subject.purge!
    end
  end
end
