require 'spec_helper'
require 'r10k/module/git'

describe R10K::Module::Git do

  describe "setting the owner and name" do
    describe "with a title of 'branan/eight_hundred'" do
      subject do
        described_class.new(
          'branan/eight_hundred',
          '/moduledir',
          {
            :git => 'git://git-server.site/branan/puppet-eight_hundred',
          }
        )
      end

      it "sets the owner to 'branan'" do
        expect(subject.owner).to eq 'branan'
      end

      it "sets the name to 'eight_hundred'" do
        expect(subject.name).to eq 'eight_hundred'
      end

      it "sets the path to '/moduledir/eight_hundred'" do
        expect(subject.path).to eq(Pathname.new('/moduledir/eight_hundred'))
      end
    end

    describe "with a title of 'modulename'" do
      subject do
        described_class.new(
          'eight_hundred',
          '/moduledir',
          {
            :git => 'git://git-server.site/branan/puppet-eight_hundred',
          }
        )
      end

      it "sets the owner to nil" do
        expect(subject.owner).to be_nil
      end

      it "sets the name to 'eight_hundred'" do
        expect(subject.name).to eq 'eight_hundred'
      end

      it "sets the path to '/moduledir/eight_hundred'" do
        expect(subject.path).to eq(Pathname.new('/moduledir/eight_hundred'))
      end
    end
  end

  describe "properties" do
    subject do
      described_class.new('boolean', '/moduledir', {:git => 'git://github.com/adrienthebo/puppet-boolean'})
    end

    it "sets the module type to :git" do
      expect(subject.properties).to include(:type => :git)
    end

    it "sets the expected version" do
      expect(subject.properties).to include(:expected => instance_of(R10K::Git::Ref))
    end

    it "sets the actual version to the revision when the revision is available" do
      head = double('head')
      expect(subject.working_dir).to receive(:current).and_return(head)
      expect(head).to receive(:sha1).and_return('35d3517e67ceeb4b485b56d4a14d38fb95516c92')
      expect(subject.properties).to include(:actual => '35d3517e67ceeb4b485b56d4a14d38fb95516c92')
    end

    it "sets the actual version (unresolvable) when the revision is unavailable" do
      head = double('head')
      expect(subject.working_dir).to receive(:current).and_return(head)
      expect(head).to receive(:sha1).and_raise(ArgumentError)
      expect(subject.properties).to include(:actual => '(unresolvable)')
    end
  end

  describe "determining the status" do
    subject do
      described_class.new(
        'boolean',
        '/moduledir',
        {
          :git => 'git://github.com/adrienthebo/puppet-boolean'
        }
      )
    end

    it "is absent when the working dir is absent" do
      expect(subject.working_dir).to receive(:exist?).and_return false
      expect(subject.status).to eq :absent
    end

    it "is mismatched Then the working dir is not a git repository" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return false
      expect(subject.status).to eq :mismatched
    end

    it "is mismatched when the expected remote does not match the actual remote" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:remote).and_return 'nope'
      expect(subject.status).to eq :mismatched
    end

    it "is outdated when the working dir is outdated" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:outdated?).and_return true
      expect(subject.status).to eq :outdated
    end

    it "is insync if all other conditions are satisfied" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:outdated?).and_return false
      expect(subject.status).to eq :insync
    end
  end
end
