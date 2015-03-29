require 'spec_helper'
require 'r10k/action/puppetfile/cri_runner'

describe R10K::Action::Puppetfile::CriRunner do

  let(:action_class) do
    Class.new do
      attr_reader :opts
      attr_reader :argv

      def initialize(opts, argv)
        @opts = opts
        @argv = argv
      end

      def call
        @opts[:runok]
      end
    end
  end

  subject(:cri_runner) { described_class.wrap(action_class)  }

  let(:opts) { {:value => :yep} }
  let(:argv) { %w[value yes] }

  describe "handling options" do
    it "sets the root to the current wd" do
      expect(cri_runner).to receive(:wd).and_return('/some/nonexistent')
      expect(cri_runner.handle_opts({})).to include(:root => '/some/nonexistent')
    end

    describe "for the moduledir" do
      before do
        allow(cri_runner).to receive(:env).and_return({'PUPPETFILE_DIR' => '/some/nonexistent/modules'})
      end

      it "sets the option from the environment when the cli option is not given" do
        opts = {}
        expect(cri_runner.handle_opts(opts)).to include(:moduledir => '/some/nonexistent/modules')
      end

      it "doesn't set the option from the environment when the cli option is given" do
        opts = {:moduledir => '/some/other/nonexistent/modules'}
        expect(cri_runner.handle_opts(opts)).to include(:moduledir => '/some/other/nonexistent/modules')
      end
    end

    describe "for the puppetfile path" do
      before do
        allow(cri_runner).to receive(:env).and_return({'PUPPETFILE' => '/some/nonexistent/Puppetfile'})
      end

      it "sets the option from the environment when the cli option is not given" do
        opts = {}
        expect(cri_runner.handle_opts(opts)).to include(:puppetfile => '/some/nonexistent/Puppetfile')
      end

      it "doesn't set the option from the environment when the cli option is given" do
        opts = {:puppetfile => '/some/other/nonexistent/modules'}
        expect(cri_runner.handle_opts(opts)).to include(:puppetfile => '/some/other/nonexistent/modules')
      end
    end
  end
end
