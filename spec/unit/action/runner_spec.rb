require 'spec_helper'
require 'r10k/action/base'
require 'puppet_forge/connection'

require 'r10k/action/runner'

describe R10K::Action::Runner do

  let(:action_class) do
    Class.new do
      attr_reader :opts
      attr_reader :argv

      def initialize(opts, argv, settings = {})
        @opts = opts
        @argv = argv
        @settings = {}
      end

      def call
        @argv.map(&:upcase)
      end
    end
  end

  subject(:runner) { described_class.new({:opts => :yep}, %w[args yes], action_class) }

  before(:each) do
    expect(runner.logger).not_to receive(:error)
  end

  describe "instantiating the wrapped class" do
    it "creates an instance of the class" do
      expect(runner.instance).to be_a_kind_of action_class
    end

    it "passes the opts and argv to the instance" do
      expect(runner.instance.opts).to eq(:opts => :yep)
      expect(runner.instance.argv).to eq(%w[args yes])
    end

    it "strips out options that the runner handles" do
      runner = described_class.new({:opts => :yep, :loglevel => 'FATAL'}, %w[args yes], action_class)
      expect(runner.instance.opts).to eq(:opts => :yep)
    end
  end

  describe "calling" do
    it "configures logging" do
      expect(runner).to receive(:setup_logging)
      runner.call
    end

    it "configures settings" do
      expect(runner).to receive(:setup_settings)
      runner.call
    end

    it "configures forge authorization" do
      expect(runner).to receive(:setup_authorization)
      runner.call
    end

    it "returns the result of the wrapped class #call method" do
      expect(runner.call).to eq %w[ARGS YES]
    end
  end

  describe "configuring settings" do
    subject(:runner) { described_class.new(options, %w[args yes], action_class) }

    let(:global_settings) { R10K::Settings.global_settings }

    before(:each) do
      expect(R10K::Settings).to receive(:global_settings).and_return(global_settings)
      allow(File).to receive(:executable?).and_return(true)
    end

    opts = {
      cachedir:       nil,
      puppet_path:    :deploy,
      generate_types: :deploy,
    }

    opts.each do |opt, conf_path|
      context "with #{opt} config setting" do
        let(:options) { { config: "spec/fixtures/unit/action/r10k_#{opt}.yaml" } }

        context "when not overridden" do
          it "uses the config value" do
            override = { "#{opt}": "/config_#{opt}" }
            overrides = if conf_path.nil?
                          override
                        else
                          { "#{conf_path}": override }
                        end
            expect(global_settings).to receive(:evaluate).with(hash_including(overrides)).and_call_original
            runner.call
          end
        end

        context "when overridden" do
          let(:options) { super().merge("#{opt.to_s.sub('_','-')}": "/overridden_#{opt}") }

          it "uses the overridden value" do
            override = { "#{opt}": "/overridden_#{opt}" }
            overrides = if conf_path.nil?
                          override
                        else
                          { "#{conf_path}": override }
                        end
            expect(global_settings).to receive(:evaluate).with(hash_including(overrides)).and_call_original
            runner.call
          end
        end
      end

      context "with complete config" do
        let(:options) { { config: "spec/fixtures/unit/action/r10k.yaml" } }
        let(:config) do
          config = {}
          opts.each do |o, path|
            if path.nil?
              config[o] = "/config_#{o}"
            else
              config[path] ||= {}
              config[path][o] = "/config_#{o}"
            end
          end
          config
        end

        context "when not overridden" do
          it "uses the config value" do
            expect(global_settings).to receive(:evaluate).with(config).and_call_original
            runner.call
          end
        end

        context "when overridden" do
          let(:options) {
            super().merge("#{opt.to_s.sub('_','-')}": "/overridden_#{opt}")
          }

          it "uses the overridden value" do
            with_overrides = config
            if conf_path.nil?
              with_overrides[opt] = "/overridden_#{opt}"
            else
              with_overrides[conf_path][opt] = "/overridden_#{opt}"
            end
            expect(global_settings).to receive(:evaluate).with(with_overrides).and_call_original
            runner.call
          end
        end
      end
    end
  end

  describe "configuring logging" do
    it "sets the log level if :loglevel is provided" do
      runner = described_class.new({:opts => :yep, :loglevel => 'FATAL'}, %w[args yes], action_class)
      expect(R10K::Logging).to receive(:level=).with('FATAL')
      runner.call
    end

    it "does not modify the loglevel if :loglevel is not provided" do
      expect(R10K::Logging).to_not receive(:level=)
      runner.call
    end
  end

  describe "configuration authorization" do
    context "when license is not present" do
      before(:each) do
        expect(R10K::Util::License).to receive(:load).and_return(nil)
      end

      it "does not set authorization header on connection class" do
        expect(PuppetForge::Connection).not_to receive(:authorization=)
        runner.setup_authorization
      end
    end

    context "when license is present but invalid" do
      before(:each) do
        expect(R10K::Util::License).to receive(:load).and_raise(R10K::Error.new('invalid license'))
      end

      it "issues warning to logger" do
        expect(runner.logger).to receive(:warn).with(/invalid license/)
        runner.setup_authorization
      end

      it "does not set authorization header on connection class" do
        expect(PuppetForge::Connection).not_to receive(:authorization=)
        runner.setup_authorization
      end
    end

    context "when license is present and valid" do
      before(:each) do
        mock_license = double('pe-license', :authorization_token => 'test token')
        expect(R10K::Util::License).to receive(:load).and_return(mock_license)
      end

      it "sets authorization header on connection class" do
        expect(PuppetForge::Connection).to receive(:authorization=).with('test token')
        runner.setup_authorization
      end
    end
  end
end
