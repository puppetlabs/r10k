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
      expect(subject.properties).to include(:expected => 'master')
    end

    it "sets the actual version to the revision when the revision is available" do
      expect(subject.repo).to receive(:head).and_return('35d3517e67ceeb4b485b56d4a14d38fb95516c92')
      expect(subject.properties).to include(:actual => '35d3517e67ceeb4b485b56d4a14d38fb95516c92')
    end

    it "sets the actual version to (unresolvable) when the revision is unavailable" do
      expect(subject.repo).to receive(:head).and_return(nil)
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

    it "delegates to the repo" do
      expect(subject.repo).to receive(:status).and_return :some_status
      expect(subject.status).to eq(:some_status)
    end
  end
end
