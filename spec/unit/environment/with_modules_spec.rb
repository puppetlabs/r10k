require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::WithModules do
  subject do
    described_class.new(
      'release42',
      '/some/nonexistent/environmentdir',
      'prefix_release42',
      {
        :type             => 'plain',
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

  describe "dealing with module conflicts" do
    context "with no module conflicts" do
      it "validates when there are no conflicts" do
        mod = instance_double('R10K::Module::Base', name: 'nonconflict', origin: :puppetfile)
        expect(subject.module_conflicts?(mod)).to eq false
      end
    end

    context "with module conflicts and default behavior" do
      it "does not raise an error" do
        mod = instance_double('R10K::Module::Base', name: 'stdlib', origin: :puppetfile)
        expect(subject.logger).to receive(:warn).with(/Puppetfile.*both define.*ignored/i)
        expect(subject.module_conflicts?(mod)).to eq true
      end
    end

    context "with module conflicts and 'error' behavior" do
      let(:subject_params) {{ :module_conflicts => 'error' }}
      it "raises an error" do
        mod = instance_double('R10K::Module::Base', name: 'stdlib', origin: :puppetfile)
        expect { subject.module_conflicts?(mod) }.to raise_error(R10K::Error, /Puppetfile.*both define.*/i)
      end
    end

    context "with module conflicts and 'override' behavior" do
      let(:subject_params) {{ :module_conflicts => 'override' }}
      it "does not raise an error" do
        mod = instance_double('R10K::Module::Base', name: 'stdlib', origin: :puppetfile)
        expect(subject.logger).to receive(:debug).with(/Puppetfile.*both define.*ignored/i)
        expect(subject.module_conflicts?(mod)).to eq true
      end
    end

    context "with module conflicts and invalid configuration" do
      let(:subject_params) {{ :module_conflicts => 'batman' }}
      it "raises an error" do
        mod = instance_double('R10K::Module::Base', name: 'stdlib', origin: :puppetfile)
        expect { subject.module_conflicts?(mod) }.to raise_error(R10K::Error, /Unexpected value.*module_conflicts.*/i)
      end
    end
  end

  describe "modules method" do
    it "returns the configured modules, and Puppetfile modules" do
      loaded = { managed_directories: [], desired_contents: [], purge_exclusions: [] }
      puppetfile_mod = instance_double('R10K::Module::Base', name: 'zebra')
      expect(subject.loader).to receive(:load).and_return(loaded.merge(modules: [puppetfile_mod]))
      returned_modules = subject.modules
      expect(returned_modules.map(&:name).sort).to eq(%w[concat exec stdlib zebra])
    end
  end
end
