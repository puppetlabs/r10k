shared_examples_for "a git ref" do

  it "can be created with an optional repository" do
    ref = described_class.new(ref, repo)
    expect(ref.repository).to eq repo
  end

  describe "comparing to another object" do
    let(:other) { double('equal') }

    it "is true if the resolved SHA1s match" do
      expect(other).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject == other).to be_true
    end

    it "is false if the resolved SHA1s don't match" do
      expect(other).to receive(:sha1).and_return '57d31c788610d7d6a1c139b4ffff0d60888ca742'
      expect(subject).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject == other).to be_false
    end

    it "is false if an error is raised while comparing the SHA1s" do
      expect(other).to receive(:sha1).and_return 'fcf6140cf3e0b3738583167702176867833ec2a7'
      expect(subject).to receive(:sha1).and_raise(ArgumentError, "Cannot resolve")
      expect(subject == other).to be_false
    end
  end
end
