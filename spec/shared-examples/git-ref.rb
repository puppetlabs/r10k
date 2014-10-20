shared_examples_for "a git ref" do

  it "can be created with an optional repository" do
    ref = described_class.new(ref, repo)
    expect(ref.repository).to eq repo
  end

  describe "comparing to another object" do
    let(:other) { R10K::Git::Ref.new('double') }

    it "is true if the resolved SHA1s match" do
      expect(other).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject == other).to be_truthy
    end

    it "is false if the resolved SHA1s don't match" do
      expect(other).to receive(:sha1).and_return '57d31c788610d7d6a1c139b4ffff0d60888ca742'
      expect(subject).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject == other).to be_falsey
    end

    it "is false if an argumenterror is raised while comparing the SHA1s" do
      expect(other).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject).to receive(:sha1).and_raise(ArgumentError, "Cannot resolve")
      expect(subject == other).to be_falsey
    end

    it "is false if a nonexistenthasherror is raised while comparing the SHA1s" do
      expect(other).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject).to receive(:sha1).and_raise(R10K::Git::UnresolvableRefError, :ref => "hash")
      expect(subject == other).to be_falsey
    end
  end
end

shared_examples_for "an immutable git ref" do
  describe "determining if the ref needs to be fetched" do
    it "is false when the ref can be resolved" do
      expect(subject).to receive(:resolvable?).and_return true
      expect(subject.fetch?).to be_falsey
    end

    it "is true when the ref cannot be resolved" do
      expect(subject).to receive(:resolvable?).and_return false
      expect(subject.fetch?).to be_truthy
    end
  end
end
