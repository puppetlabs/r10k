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
end
