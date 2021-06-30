require 'spec_helper'
require 'r10k/action/base'
require 'puppet_forge/connection'

require 'r10k/action/runner'

describe R10K::Action::Runner do

  let(:action_class) do
    Class.new do
      attr_reader :opts
      attr_reader :argv
      attr_reader :settings

      def initialize(opts, argv, settings = {})
        @opts = opts
        @argv = argv
        @settings = settings
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

    it "does not modify the loglevel if :logle1vel is not provided" do
      expect(R10K::Logging).to_not receive(:level=)
      runner.call
    end
  end

  describe "configuring github app credentials" do
    it 'errors if app id is passed without ssl key' do
      runner = described_class.new(
        { 'github-app-id': '/nonexistent', },
        %w[args yes],
        action_class
      )
      expect{ runner.call }.to raise_error(R10K::Error, /Both id and private key are required/)
    end

    it 'errors if ssl key is passed without app id' do
      runner = described_class.new(
        { 'github-app-key': '/nonexistent', },
        %w[args yes],
        action_class
      )
      expect{ runner.call }.to raise_error(R10K::Error, /Both id and private key are required/)
    end

    it 'errors if both token and app id paths are passed' do
      runner = described_class.new(
        { 'github-app-id': '/nonexistent', 'oauth-token': '/also/fake' },
        %w[args yes],
        action_class
      )
      expect{ runner.call }.to raise_error(R10K::Error, /both a Github App and a token/)
    end

    it 'errors if both token and ssh key paths are passed' do
      runner = described_class.new(
        { 'github-app-key': '/nonexistent', 'private-key': '/also/fake' },
        %w[args yes],
        action_class
      )
      expect{ runner.call }.to raise_error(R10K::Error, /Cannot specify both/)
    end

    it 'saves the parameters in settings hash' do
      runner = described_class.new(
        { 'github-app-id': '123456', 'github-app-key': '/my/ssl/key', 'github-app-ttl': '600' },
        %w[args yes],
        action_class
      )
      runner.call
      expect(runner.instance.settings[:git][:github_app_id]).to eq('123456')
      expect(runner.instance.settings[:git][:github_app_key]).to eq('/my/ssl/key')
      expect(runner.instance.settings[:git][:github_app_ttl]).to eq('600')
    end
  end

  describe "configuring git credentials" do
    it 'errors if both token and key paths are passed' do
      runner = described_class.new({ 'oauth-token': '/nonexistent',
                                     'private-key': '/also/fake' }, %w[args yes], action_class)
      expect{ runner.call }.to raise_error(R10K::Error, /Cannot specify both/)
    end

    it 'saves the sshkey path in settings hash' do
      runner = described_class.new({ 'private-key': '/my/ssh/key' }, %w[args yes], action_class)
      runner.call
      expect(runner.instance.settings[:git][:private_key]).to eq('/my/ssh/key')
    end

    it 'overrides per-repo sshkey in settings hash' do
      runner = described_class.new({ config: "spec/fixtures/unit/action/r10k_creds.yaml",
                                     'private-key': '/my/ssh/key' },
                                     %w[args yes],
                                     action_class)
      runner.call
      expect(runner.instance.settings[:git][:private_key]).to eq('/my/ssh/key')
      expect(runner.instance.settings[:git][:repositories].count).to eq(2)
      runner.instance.settings[:git][:repositories].each do |repo_settings|
        expect(repo_settings[:private_key]).to eq('/my/ssh/key')
      end
    end

    it 'saves the token path in settings hash' do
      runner = described_class.new({ 'oauth-token': '/my/token/path' }, %w[args yes], action_class)
      runner.call
      expect(runner.instance.settings[:git][:oauth_token]).to eq('/my/token/path')
    end

    it 'overrides per-repo oauth token in settings hash' do
      runner = described_class.new({ config: "spec/fixtures/unit/action/r10k_creds.yaml",
                                     'oauth-token': '/my/token' },
                                     %w[args yes],
                                     action_class)
      runner.call
      expect(runner.instance.settings[:git][:oauth_token]).to eq('/my/token')
      expect(runner.instance.settings[:git][:repositories].count).to eq(2)
      runner.instance.settings[:git][:repositories].each do |repo_settings|
        expect(repo_settings[:oauth_token]).to eq('/my/token')
      end
    end
  end

  describe "configuration authorization" do
    context "settings auth" do
      it "sets the configured token as the forge authorization header" do
        options = { config: "spec/fixtures/unit/action/r10k_forge_auth.yaml" }
        runner = described_class.new(options, %w[args yes], action_class)

        expect(PuppetForge).to receive(:host=).with('http://private-forge.com')
        expect(PuppetForge::Connection).to receive(:authorization=).with('faketoken')
        expect(PuppetForge::Connection).to receive(:authorization).and_return('faketoken')
        expect(R10K::Util::License).not_to receive(:load)
        runner.setup_settings
        runner.setup_authorization
      end

      it 'errors if no custom forge URL is set' do
        options = { config: "spec/fixtures/unit/action/r10k_forge_auth_no_url.yaml" }
        runner = described_class.new(options, %w[args yes], action_class)
        expect(PuppetForge::Connection).not_to receive(:authorization=).with('faketoken')

        expect { runner.setup_settings }.to raise_error(R10K::Error, /Cannot specify a Forge auth/)
      end
    end

    context "license auth" do
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
end
