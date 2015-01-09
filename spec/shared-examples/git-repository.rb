shared_examples_for "a git repository" do

  it "does not exist if the repo is not present" do
    expect(subject.exist?).to be_falsey
  end

  describe "listing tags" do
    before do
      subject.clone(remote)
    end

    it "lists all tags in alphabetical order" do
      expect(subject.tags).to eq(%w[0.9.0 0.9.0-rc1 1.0.0 1.0.1])
    end
  end

  describe "resolving refs" do
    before do
      subject.clone(remote)
    end

    it "can resolve branches" do
      expect(subject.resolve('master')).to eq '157011a4eaa27f1202a9d94335ee4876b26d377e'
    end

    it "can resolve tags" do
      expect(subject.resolve('1.0.0')).to eq '14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c'
    end

    it "can resolve commits" do
      expect(subject.resolve('3084373e8d181cf2fea5b4ade2690ba22872bd67')).to eq '3084373e8d181cf2fea5b4ade2690ba22872bd67'
    end

    it "returns nil when the object cannot be resolved" do
      expect(subject.resolve('1.2.3')).to be_nil
    end
  end
end
