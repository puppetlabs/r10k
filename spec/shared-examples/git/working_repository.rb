RSpec.shared_examples "a git working repository" do
  describe "cloning" do
    it "creates a working copy of the repo" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
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
      it "can check out tags" do
        subject.clone(remote, {:ref => '1.0.0'})
        expect(subject.head).to eq "14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c"
      end

      it "can check out remote branches" do
        subject.clone(remote, {:ref => 'origin/0.9.x'})
        expect(subject.head).to eq "3084373e8d181cf2fea5b4ade2690ba22872bd67"
      end

      it "can check out commits" do
        subject.clone(remote, {:ref => '14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c'})
        expect(subject.head).to eq "14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c"
      end
    end

    describe "with a reference repository" do
      it "adds the reference repository to the alternates directory" do
        subject.clone(remote, {:reference => remote})
        alternates = subject.alternates.to_a
        expect(alternates.size).to eq 1
        expect(alternates[0]).to match_realpath File.join(remote, 'objects')
      end
    end

    context "without a proxy" do
      before(:each) do
        allow(R10K::Git).to receive(:get_proxy_for_remote).with(remote).and_return(nil)
      end

      it 'does not change proxy ENV' do
        expect(ENV).to_not receive(:[]=)
        expect(ENV).to_not receive(:update)

        subject.clone(remote)
      end
    end

    context "with a proxy" do
      before(:each) do
        allow(R10K::Git).to receive(:get_proxy_for_remote).with(remote).and_return('http://proxy.example.com:3128')
      end

      it "manages proxy-related ENV vars" do
        # Sets proxy settings.
        ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy'].each do |var|
          expect(ENV).to receive(:[]=).with(var, 'http://proxy.example.com:3128')
        end

        # Resets proxy settings when done.
        expect(ENV).to receive(:update).with(hash_including('HTTPS_PROXY' => nil))

        subject.clone(remote)
      end
    end
  end

  describe "updating the repo" do
    let(:tag_090) { subject.git_dir + 'refs' + 'tags' + '0.9.0' }
    let(:packed_refs) { subject.git_dir + 'packed-refs' }

    before do
      subject.clone(remote)
      tag_090.delete if tag_090.exist?
      packed_refs.delete if packed_refs.exist?
    end

    it "fetches objects from the remote" do
      expect(subject.tags).to_not include('0.9.0')
      subject.fetch
      expect(subject.tags).to include('0.9.0')
    end

    context "without a proxy" do
      before(:each) do
        allow(R10K::Git).to receive(:get_proxy_for_remote).with(remote).and_return(nil)
      end

      it 'does not change proxy ENV' do
        expect(ENV).to_not receive(:[]=)
        expect(ENV).to_not receive(:update)

        subject.fetch
      end
    end

    context "with a proxy" do
      before(:each) do
        allow(R10K::Git).to receive(:get_proxy_for_remote).with(remote).and_return('http://proxy.example.com:3128')
      end

      it "manages proxy-related ENV vars" do
        # Sets proxy settings.
        ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy'].each do |var|
          expect(ENV).to receive(:[]=).with(var, 'http://proxy.example.com:3128')
        end

        # Resets proxy settings when done.
        expect(ENV).to receive(:update).with(hash_including('HTTPS_PROXY' => nil))

        subject.fetch
      end
    end
  end

  describe "listing branches" do
    before do
      subject.clone(remote)
    end

    it "lists the local branches" do
      expect(subject.branches).to eq(%w[master])
    end
  end

  describe "listing the origin" do
    it "is nil if the remote is not set" do
      expect(subject.origin).to be_nil
    end

    it "is the remote URL when set" do
      subject.clone(remote)
      expect(subject.origin).to eq remote
    end
  end

  describe "checking out ref" do
    before(:each) do
      subject.clone(remote)
      File.open(File.join(subject.path, 'README.markdown'), 'a') { |f| f.write('local modifications!') }
    end

    context "with force = true" do
      it "should revert changes in managed files" do
        subject.checkout(subject.head, {:force => true})
        expect(File.read(File.join(subject.path, 'README.markdown')).include?('local modifications!')).to eq false
      end
    end

    context "with force = false" do
      it "should not revert changes in managed files" do
        expect { subject.checkout(subject.head, {:force => false}).to raise_error(Rugged::CheckoutError) }
        expect(File.read(File.join(subject.path, 'README.markdown')).include?('local modifications!')).to eq true
      end
    end
  end

  describe "checking if worktree is dirty" do
    before do
      subject.clone(remote)
    end

    context "with no local changes" do
      it "reports worktree as not dirty" do
        expect(subject.dirty?).to be false
      end
    end

    context "with local changes" do
      before(:each) do
        File.open(File.join(subject.path, 'README.markdown'), 'a') { |f| f.write('local modifications!') }
      end

      it "logs and reports worktree as dirty" do
        expect(subject.logger).to receive(:debug).with(/found local modifications in.*README\.markdown/i)
        expect(subject.logger).to receive(:debug1)

        expect(subject.dirty?).to be true
      end
    end
  end
end
