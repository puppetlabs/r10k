require 'spec_helper'
require 'r10k/git/working_repository'

describe R10K::Git::WorkingRepository do
  include_context 'Git integration'

  let(:remote) { File.join(remote_path, 'puppet-boolean.git') }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'working-repo' }

  after do
    FileUtils.remove_entry_secure(basedir)
  end

  subject { described_class.new(basedir, dirname) }

  describe "cloning" do
    it "creates a working copy of the repo" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
    end

    it "sets the remote origin url to the provided url" do
      subject.clone(remote)
      expect(subject.origin).to eq remote
    end

    describe "using the default branch" do
      describe "and the remote HEAD is 'master'" do
        it "checks out the default branch" do
          subject.clone(remote)
          expect(subject.head).to eq "157011a4eaa27f1202a9d94335ee4876b26d377e"
        end
      end

      describe "and the remote HEAD is '0.9.x'" do
        before do
          File.open(File.join(remote, 'HEAD'), 'w') do |fh|
            fh.write('ref: refs/heads/0.9.x')
          end
        end

        after do
          clear_remote_path
          populate_remote_path
        end

        it "checks out the default branch" do
          subject.clone(remote)
          expect(subject.head).to eq "3084373e8d181cf2fea5b4ade2690ba22872bd67"
        end
      end
    end

    describe "using an explicit ref" do
      it "checks out the given ref" do
        subject.clone(remote, {:ref => '1.0.0'})
        expect(subject.head).to eq "14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c"
      end
    end

    describe "with a reference repository" do
      it "adds the reference repository to the alternates directory" do
        subject.clone(remote, {:reference => remote})
        expect(subject.alternates.to_a).to eq [File.join(remote, 'objects')]
      end
    end
  end
end
