require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::WithModules do
  subject do
    described_class.new(
      'release42',
      '/some/nonexistent/environmentdir',
      'prefix_release42',
      {
        :type             => 'bare',
        :modules          => {
          'puppetlabs-stdlib' => { local: true },
          'puppetlabs-concat' => { local: true },
          'puppetlabs-exec'   => { local: true },
        }
      }.merge(subject_params)
    )
  end

  # Default no additional params
  let(:subject_params) { {} }

  describe "dealing with Puppetfile module conflicts" do
    context "with no module conflicts" do
      it "validates when there are no conflicts" do
        mod = instance_double('R10K::Module::Base', :name => 'nonconflict')
        expect(subject.puppetfile).to receive(:load)
        expect(subject.puppetfile).to receive(:modules).and_return [mod]
        expect { subject.validate_no_module_conflicts }.not_to raise_error
      end
    end

    context "with module conflicts and default behavior" do
      it "does not raise an error" do
        mod = instance_double('R10K::Module::Base', :name => 'stdlib')
        expect(subject.puppetfile).to receive(:load)
        expect(subject.puppetfile).to receive(:modules).at_least(:once).and_return([mod])
        expect(subject.logger).to receive(:warn).with(/Puppetfile.*both define.*ignored/i)
        expect { subject.validate_no_module_conflicts }.not_to raise_error
      end

      it "does not visit puppetfile modules overridden by environment modules" do
        mod1 = instance_double('R10K::Module::Base', name: 'nondup', dirname: '/dev/null', cachedir: :none)
        mod2 = instance_double('R10K::Module::Base', name: 'stdlib', dirname: '/dev/null', cachedir: :none)

        pf = R10K::Puppetfile.new('/some/nonexistent/path', nil, nil)
        pf.instance_variable_set(:@managed_content, {'/dev/null' => []})
        pf.instance_variable_set(:@modules, [mod1, mod2])

        allow(subject).to receive(:puppetfile).and_return(pf)
        allow(pf).to receive(:load).and_return(nil)

        visitor = spy('visitor')
        expect(visitor).to receive(:visit).with(:environment, subject) { |&block| block.call }
        expect(visitor).to receive(:visit).with(:puppetfile, pf) { |&block| block.call }

        expect(mod1).to receive(:accept)
        expect(mod2).not_to receive(:accept)

        subject.accept(visitor)
      end
    end

    context "with module conflicts and 'error' behavior" do
      let(:subject_params) {{ :module_conflicts => 'error' }}
      it "raises an error" do
        mod = instance_double('R10K::Module::Base', :name => 'stdlib')
        expect(subject.puppetfile).to receive(:load)
        expect(subject.puppetfile).to receive(:modules).at_least(:once).and_return([mod])
        expect { subject.validate_no_module_conflicts }.to raise_error(R10K::Error, /Puppetfile.*defined.*conflict/i)
      end
    end

    context "with module conflicts and 'override_puppetfile' behavior" do
      let(:subject_params) {{ :module_conflicts => 'override_puppetfile' }}
      it "does not raise an error" do
        mod = instance_double('R10K::Module::Base', :name => 'stdlib')
        expect(subject.puppetfile).to receive(:load)
        expect(subject.puppetfile).to receive(:modules).at_least(:once).and_return([mod])
        expect(subject.logger).to receive(:debug).with(/Puppetfile.*both define.*ignored/i)
        expect { subject.validate_no_module_conflicts }.not_to raise_error
      end
    end

    context "with module conflicts and invalid configuration" do
      let(:subject_params) {{ :module_conflicts => 'batman' }}
      it "raises an error" do
        mod = instance_double('R10K::Module::Base', :name => 'stdlib')
        expect(subject.puppetfile).to receive(:load)
        expect(subject.puppetfile).to receive(:modules).at_least(:once).and_return([mod])
        expect { subject.validate_no_module_conflicts }.to raise_error(R10K::Error, /Unexpected value.*module_conflicts/i)
      end
    end
  end

  describe "modules method" do
    it "overrides duplicates, choosing the environment version" do
      puppetfile_mod = instance_double('R10K::Module::Base', name: 'stdlib')
      expect(subject.puppetfile).to receive(:load)
      expect(subject.puppetfile).to receive(:modules).and_return [puppetfile_mod]
      returned_modules = subject.modules
      expect(returned_modules.map(&:name).sort).to eq(%w[concat exec stdlib])

      # Make sure the module that was picked was the environment one, not the Puppetfile one
      selected_stdlib = returned_modules.find { |m| m.name == 'stdlib' }
      expect(selected_stdlib).not_to eq(puppetfile_mod)
    end
  end
end
