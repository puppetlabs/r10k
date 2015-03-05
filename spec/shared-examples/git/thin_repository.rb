RSpec.shared_examples "a git thin repository" do
  describe "cloning" do
    it "creates a working copy of the repo" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
    end

    it "sets the remote origin url to the provided url" do
      subject.clone(remote)
      expect(subject.origin).to eq remote
    end

    it "sets the remote cache url to the path to the cache repo" do
      subject.clone(remote)
      expect(subject.cache).to eq cacherepo.git_dir.to_s
    end

    it "adds the cache repo to the alternates file" do
      subject.clone(remote)
      objectpath = cacherepo.git_dir + 'objects'
      alternates = subject.alternates.to_a
      expect(alternates.size).to eq 1
      expect(alternates[0]).to match_realpath objectpath
    end
  end
end
