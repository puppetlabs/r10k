RSpec.shared_examples "a git bare repository" do

  describe "checking for the presence of the repo" do
    it "exists if the repo is present" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
    end

    it "doesn't exist if the repo is not present" do
      expect(subject.exist?).to be_falsey
    end
  end

  describe "cloning the repo" do
    it "creates the repo at the expected location" do
      subject.clone(remote)
      config = File.read(File.join(basedir, dirname, 'config'))
      expect(config).to match(remote)
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

    it "lists all branches in alphabetical order" do
      expect(subject.branches).to eq(%w[0.9.x master])
    end
  end

  describe "determining ref type" do
    before do
      subject.clone(remote)
    end

    it "can infer the type of a branch ref" do
      expect(subject.ref_type('master')).to eq :branch
    end

    it "can infer the type of a tag ref" do
      expect(subject.ref_type('1.0.0')).to eq :tag
    end

    it "can infer the type of a commit" do
      expect(subject.ref_type('3084373e8d181cf2fea5b4ade2690ba22872bd67')).to eq :commit
    end

    it "returns :unknown when the type cannot be inferred" do
      expect(subject.ref_type('1.2.3')).to eq :unknown
    end
  end
end
