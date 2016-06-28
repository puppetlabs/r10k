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
      'spec/fixtures/unit/util/purgeable/managed_one/new_1',
      'spec/fixtures/unit/util/purgeable/managed_one/managed_subdir_1',
      'spec/fixtures/unit/util/purgeable/managed_one/managed_subdir_1/subdir_expected_1',
      'spec/fixtures/unit/util/purgeable/managed_one/managed_subdir_1/subdir_new_1',
      'spec/fixtures/unit/util/purgeable/managed_two/expected_2',
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

  context 'without recurse option' do
    let(:recurse) { false }

    describe '#current_contents' do
      it 'collects direct contents of all managed directories' do
        expect(subject.current_contents(recurse)).to contain_exactly(/\/expected_1/, /\/expected_2/, /\/unmanaged_1/, /\/unmanaged_2/, /\/managed_subdir_1/)
      end
    end

    describe '#pending_contents' do
      it 'collects desired_contents that do not yet exist' do
        expect(subject.pending_contents(recurse)).to include(/\/new_1/, /\/new_2/)
      end
    end

    describe '#stale_contents' do
      context 'with no whitelist or exclusions' do
        let(:exclusions) { [] }
        let(:whitelist) { [] }

        it 'collects current_contents that should not exist' do
          expect(subject.stale_contents(recurse, exclusions, whitelist)).to contain_exactly(/\/unmanaged_1/, /\/unmanaged_2/)
        end
      end
    end

    describe '#purge!' do
      let(:exclusions) { [] }
      let(:whitelist) { [] }
      let(:purge_opts) { { recurse: recurse, whitelist: whitelist } }

      it 'does nothing when there is no stale_contents' do
        allow(subject).to receive(:stale_contents).and_return([])

        expect(FileUtils).to_not receive(:rm_rf)

        subject.purge!(purge_opts)
      end

      it 'recursively deletes all stale_contents' do
        subject.stale_contents(recurse, exclusions, whitelist).each do |stale|
          expect(FileUtils).to receive(:rm_r).with(stale, hash_including(secure: true))
        end

        subject.purge!(purge_opts)
      end
    end
  end

  context 'with recurse option' do
    let(:recurse) { true }

    describe '#current_contents' do
      it 'collects contents of all managed directories recursively' do
        expect(subject.current_contents(recurse)).to contain_exactly(/\/expected_1/, /\/expected_2/, /\/unmanaged_1/, /\/unmanaged_2/, /\/managed_subdir_1/, /\/subdir_expected_1/, /\/subdir_unmanaged_1/)
      end
    end

    describe '#pending_contents' do
      it 'collects desired_contents that do not yet exist recursively' do
        expect(subject.pending_contents(recurse)).to include(/\/new_1/, /\/new_2/, /\/subdir_new_1/)
      end
    end

    describe '#stale_contents' do
      context 'with no whitelist or exclusions' do
        let(:exclusions) { [] }
        let(:whitelist) { [] }

        it 'collects current_contents that should not exist recursively' do
          expect(subject.stale_contents(recurse, exclusions, whitelist)).to contain_exactly(/\/unmanaged_1/, /\/unmanaged_2/, /\/subdir_unmanaged_1/)
        end
      end
    end

    describe '#purge!' do
      let(:exclusions) { [] }
      let(:whitelist) { [] }
      let(:purge_opts) { { recurse: recurse, whitelist: whitelist } }

      it 'does nothing when there is no stale_contents' do
        allow(subject).to receive(:stale_contents).and_return([])

        expect(FileUtils).to_not receive(:rm_r)

        subject.purge!(purge_opts)
      end

      it 'recursively deletes all stale_contents' do
        subject.stale_contents(recurse, exclusions, whitelist).each do |stale|
          expect(FileUtils).to receive(:rm_r).with(stale, hash_including(secure: true))
        end

        subject.purge!(purge_opts)
      end
    end
  end

  describe "user whitelist functionality" do
    context "non-recursive whitelist glob" do
      let(:whitelist) { managed_directories.collect { |dir| File.join(dir, "*unmanaged*") } }
      let(:purge_opts) { { recurse: true, whitelist: whitelist } }

      describe '#purge!' do
        it 'does not purge items matching glob at root level' do
          allow(FileUtils).to receive(:rm_r)
          expect(FileUtils).to_not receive(:rm_r).with(/\/unmanaged_[12]/, anything)

          subject.purge!(purge_opts)
        end
      end
    end

    context "recursive whitelist glob" do
      let(:whitelist) { managed_directories.collect { |dir| File.join(dir, "**", "*unmanaged*") } }
      let(:purge_opts) { { recurse: true, whitelist: whitelist } }

      describe '#purge!' do
        it 'does not purge items matching glob at any level' do
          expect(FileUtils).to_not receive(:rm_r)
          subject.purge!(purge_opts)
        end
      end
    end
  end
end
