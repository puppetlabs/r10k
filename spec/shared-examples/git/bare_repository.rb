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

  describe "extracting file contents at revision" do
    before do
      subject.clone(remote)
    end

    it "can extract at a branch ref" do
      content = subject.blob_at('0.9.x', 'Modulefile')
      expect(content.size).to eq 439
    end

    it "can extract at a full SHA ref" do
      content = subject.blob_at('baa30e4d34b83187624335236cc91ecb18d9ceff', 'README.markdown')
      expect(content.size).to eq 2360
    end

    it "can extract at a short SHA ref" do
      content = subject.blob_at('baa30e4', 'README.markdown')
      expect(content.size).to eq 2360
    end

    it "can extract at a tag ref" do
      content = subject.blob_at('0.9.0-rc1', 'Modulefile')
      expect(content.size).to eq 443
    end
  end
end
