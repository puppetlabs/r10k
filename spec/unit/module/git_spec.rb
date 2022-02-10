require 'spec_helper'
require 'r10k/module/git'

describe R10K::Module::Git do
  let(:mock_repo) do
    instance_double("R10K::Git::StatefulRepository")
  end

  before(:each) do
    allow(R10K::Git::StatefulRepository).to receive(:new).and_return(mock_repo)
  end


  describe "statically determined version support" do
    it 'returns a given commit' do
      static_version = described_class.statically_defined_version('branan/eight_hundred', { git: 'my/remote', commit: '123adf' })
      expect(static_version).to eq('123adf')
    end

    it 'returns a given tag' do
      static_version = described_class.statically_defined_version('branan/eight_hundred', { git: 'my/remote', tag: 'v1.2.3' })
      expect(static_version).to eq('v1.2.3')
    end

    it 'returns a ref if it looks like a full commit sha' do
      static_version = described_class.statically_defined_version('branan/eight_hundred', { git: 'my/remote', ref: '1234567890abcdef1234567890abcdef12345678' })
      expect(static_version).to eq('1234567890abcdef1234567890abcdef12345678')
    end

    it 'returns nil for any non-sha-like ref' do
      static_version = described_class.statically_defined_version('branan/eight_hundred', { git: 'my/remote', ref: 'refs/heads/main' })
      expect(static_version).to eq(nil)
    end

    it 'returns nil for branches' do
      static_version = described_class.statically_defined_version('branan/eight_hundred', { git: 'my/remote', branch: 'main' })
      expect(static_version).to eq(nil)
    end
  end

  describe "setting the owner and name" do
    describe "with a title of 'branan/eight_hundred'" do
      subject do
        described_class.new(
          'branan/eight_hundred',
          '/moduledir',
          { :git => 'git://git-server.site/branan/puppet-eight_hundred' }
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
          { :git => 'git://git-server.site/branan/puppet-eight_hundred' }
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
      described_class.new('boolean', '/moduledir', {:git => 'git://git.example.com/adrienthebo/puppet-boolean',
                                                    overrides: {modules: {default_ref: "main"}}})
    end

    before(:each) do
      allow(mock_repo).to receive(:resolve).with('main').and_return('abc123')
      allow(mock_repo).to receive(:head).and_return('abc123')
    end

    it "sets the module type to :git" do
      expect(subject.properties).to include(:type => :git)
    end

    it "sets the expected version" do
      expect(subject.properties).to include(:expected => 'main')
    end

    it "sets the actual version to the revision when the revision is available" do
      expect(mock_repo).to receive(:head).and_return('35d3517e67ceeb4b485b56d4a14d38fb95516c92')
      expect(subject.properties).to include(:actual => '35d3517e67ceeb4b485b56d4a14d38fb95516c92')
    end

    it "sets the actual version to (unresolvable) when the revision is unavailable" do
      expect(mock_repo).to receive(:head).and_return(nil)
      expect(subject.properties).to include(:actual => '(unresolvable)')
    end
  end

  describe 'syncing the repo' do
    let(:module_org) { "coolorg" }
    let(:module_name) { "coolmod" }
    let(:title) { "#{module_org}-#{module_name}" }
    let(:dirname) { Pathname.new(Dir.mktmpdir) }
    let(:spec_path) { dirname + module_name + 'spec' }
    subject { described_class.new(title, dirname, {overrides: {modules: {default_ref: "main"}}}) }

    before(:each) do
      allow(mock_repo).to receive(:resolve).with('main').and_return('abc123')
    end

    it 'defaults to deleting the spec dir' do
      FileUtils.mkdir_p(spec_path)
      allow(mock_repo).to receive(:sync)
      subject.sync
      expect(Dir.exist?(spec_path)).to eq false
    end

    it 'returns true if repo was updated' do
      expect(mock_repo).to receive(:sync).and_return(true)
      expect(subject.sync).to be true
    end

    it 'returns false if repo was not updated (in-sync)' do
      expect(mock_repo).to receive(:sync).and_return(false)
      expect(subject.sync).to be false
    end

    it 'returns false if `should_sync?` is false' do
      # modules do not sync if they are not requested
      mod = described_class.new(title, dirname, { overrides: { modules: { requested_modules: ['other_mod'] } } })
      expect(mod.sync).to be false
    end
  end

  describe "determining the status" do
    subject do
      described_class.new(
        'boolean',
        '/moduledir',
        { :git => 'git://git.example.com/adrienthebo/puppet-boolean' }
      )
    end

    it "delegates to the repo" do
      expect(subject).to receive(:version).and_return 'main'
      expect(mock_repo).to receive(:status).with('main').and_return :some_status

      expect(subject.status).to eq(:some_status)
    end
  end

  describe "option parsing" do
    def test_module(extra_opts, env=nil)
      described_class.new('boolean', '/moduledir', base_opts.merge(extra_opts), env)
    end

    let(:base_opts) { { git: 'git://git.example.com/adrienthebo/puppet-boolean' } }

    before(:each) do
      allow(mock_repo).to receive(:head).and_return('abc123')
    end

    it "raises an argument error when no refs are supplied" do
      expect{test_module({}).properties}.to raise_error(ArgumentError, /unable.*desired ref.*no default/i)
    end

    describe 'the overrides->modules->default_ref' do
      context 'specifying a default_ref only' do
        let(:opts) { {overrides: {modules: {default_ref: 'cranberry'}}} }
        it "sets the expected ref to default_ref" do
          expect(mock_repo).to receive(:resolve).with('cranberry').and_return('def456')
          expect(test_module(opts).properties).to include(expected: 'cranberry')
        end
      end

      context 'specifying a default_ref and a default_branch' do
        let(:opts) { {default_branch: 'orange',  overrides: {modules: {default_ref: 'cranberry'}}}}
        it "sets the expected ref to the default_branch" do
          expect(mock_repo).to receive(:resolve).with('orange').and_return('def456')
          expect(test_module(opts).properties).to include(expected: 'orange')
        end
      end
    end

    describe "desired ref" do
      context "specifying a static desired branch" do
        let(:opts) { { branch: 'banana' } }

        it "sets expected to specified branch name" do
          expect(mock_repo).to receive(:resolve).with('banana').and_return('def456')

          mod = test_module(opts)
          expect(mod.properties).to include(expected: 'banana')
        end
      end

      context "specifying a static desired tag" do
        let(:opts) { { tag: '1.2.3' } }

        it "sets expected to specified tag" do
          expect(mock_repo).to receive(:resolve).with('1.2.3').and_return('def456')

          mod = test_module(opts)
          expect(mod.properties).to include(expected: '1.2.3')
        end
      end

      context "specifying a static desired commit sha" do
        let(:opts) { { commit: 'ace789' } }

        it "sets expected to specified commit sha" do
          expect(mock_repo).to receive(:resolve).with('ace789').and_return('ace789')

          mod = test_module(opts)
          expect(mod.properties).to include(expected: 'ace789')
        end
      end

      context "specifying a static desired ref" do
        before(:each) do
          expect(mock_repo).to receive(:resolve).and_return('abc123')
        end

        it "accepts a branch name" do
          mod = test_module(ref: 'banana')
          expect(mod.properties).to include(expected: 'banana')
        end

        it "accepts a tag name" do
          mod = test_module(ref: '1.2.3')
          expect(mod.properties).to include(expected: '1.2.3')
        end

        it "accepts a commit sha" do
          mod = test_module(ref: 'abc123')
          expect(mod.properties).to include(expected: 'abc123')
        end
      end

      context "specifying branch to :control_branch" do
        let(:mock_env) { instance_double("R10K::Environment::Git", ref: 'env_branch') }

        context "when module belongs to an environment and matching branch is resolvable" do
          before(:each) do
            expect(mock_repo).to receive(:resolve).with(mock_env.ref).and_return('abc123')
          end

          it "tracks environment branch" do
            mod = test_module({branch: :control_branch}, mock_env)
            expect(mod.properties).to include(expected: mock_env.ref)
          end
        end

        context "when module does not belong to an environment" do
          it "leaves desired_ref unchanged" do
            mod = test_module(branch: :control_branch)
            expect(mod.desired_ref).to eq(:control_branch)
          end

          it "warns control branch may be unresolvable" do
            logger = double("logger")
            allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
            expect(logger).to receive(:warn).with(/Cannot track control repo branch.*boolean.*/)

            test_module(branch: :control_branch)
          end

          context "when default ref is provided and resolvable" do
            it "uses default ref" do
              expect(mock_repo).to receive(:resolve).with('default').and_return('abc123')
              mod = test_module({branch: :control_branch, default_branch: 'default'})

              expect(mod.properties).to include(expected: 'default')
            end
          end

          context "when default ref is provided and not resolvable" do
            it "raises appropriate error" do
              expect(mock_repo).to receive(:resolve).with('default').and_return(nil)
              mod = test_module({branch: :control_branch, default_branch: 'default'})

              expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*could not resolve control repo branch.*or resolve default/i)
            end
          end

          context "when default ref is not provided" do
            it "raises appropriate error" do
              mod = test_module({branch: :control_branch})

              expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*could not resolve control repo branch.*no default provided/i)
            end
          end
        end

        context "when module does not have matching branch" do
          before(:each) do
            allow(mock_repo).to receive(:resolve).with(mock_env.ref).and_return(nil)
          end

          context "when default ref is provided and resolvable" do
            it "uses default ref" do
              expect(mock_repo).to receive(:resolve).with('default').and_return('abc123')
              mod = test_module({branch: :control_branch, default_branch: 'default'}, mock_env)

              expect(mod.properties).to include(expected: 'default')
            end
          end

          context "when default ref is provided and not resolvable" do
            it "raises appropriate error" do
              expect(mock_repo).to receive(:resolve).with('default').and_return(nil)
              mod = test_module({branch: :control_branch, default_branch: 'default'}, mock_env)

              expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*could not resolve desired.*or resolve default/i)
            end
          end

          context "when default ref is not provided" do
            it "raises appropriate error" do
              mod = test_module({branch: :control_branch}, mock_env)

              expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*no default provided/i)
            end
          end
        end

        context "when using default_branch_override" do
          before(:each) do
            allow(mock_repo).to receive(:resolve).with(mock_env.ref).and_return(nil)
          end

          context "and the default branch override is resolvable" do
            it "uses the override" do
              expect(mock_repo).to receive(:resolve).with('default_override').and_return('5566aabb')
              mod = test_module({branch: :control_branch,
                                 default_branch: 'default',
                                 default_branch_override: 'default_override'},
                                 mock_env)
              expect(mod.properties).to include(expected: 'default_override')
            end
          end

          context "and the default branch override is not resolvable" do
            context "and default branch is provided" do
              it "falls back to the default" do
                expect(mock_repo).to receive(:resolve).with('default_override').and_return(nil)
                expect(mock_repo).to receive(:resolve).with('default').and_return('5566aabb')
                mod = test_module({branch: :control_branch,
                                   default_branch: 'default',
                                   default_branch_override: 'default_override'},
                                   mock_env)
                expect(mod.properties).to include(expected: 'default')
              end
            end

            context "and default branch is not provided" do
              it "raises the appropriate error" do
                expect(mock_repo).to receive(:resolve).with('default_override').and_return(nil)
                mod = test_module({branch: :control_branch,
                                   default_branch_override: 'default_override'},
                                   mock_env)

                expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*or resolve the default branch override.*no default provided/i)
              end
            end

            context "and default branch is not resolvable" do
              it "raises the appropriate error" do
                expect(mock_repo).to receive(:resolve).with('default_override').and_return(nil)
                expect(mock_repo).to receive(:resolve).with('default').and_return(nil)
                mod = test_module({branch: :control_branch,
                                   default_branch: 'default',
                                   default_branch_override: 'default_override'},
                                   mock_env)

                expect { mod.properties }.to raise_error(ArgumentError, /unable to manage.*or resolve the default branch override.*or resolve default/i)
              end
            end
          end
        end
      end
    end
  end
end
