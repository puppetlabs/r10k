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
      it "sets the option from the cli option if given" do
        opts = {:moduledir => '/some/other/nonexistent/modules'}
        expect(cri_runner.handle_opts(opts)).to include(:moduledir => '/some/other/nonexistent/modules')
      end
    end

    describe "for the puppetfile path" do
      it "sets the option from the cli option if given" do
        opts = {:puppetfile => '/some/other/nonexistent/modules'}
        expect(cri_runner.handle_opts(opts)).to include(:puppetfile => '/some/other/nonexistent/modules')
      end
    end
  end
end
