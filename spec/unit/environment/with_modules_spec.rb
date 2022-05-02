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

  describe "module options" do
    let(:subject_params) {{
      :modules => {
        'hieradata' => {
          :type => 'git',
          :source => 'git@git.example.com:site_data.git',
          :install_path => ''
        },
        'site_data_2' => {
          :type => 'git',
          :source => 'git@git.example.com:site_data.git',
          :install_path => 'subdir'
        },

      }
    }}

    it "should support empty install_path" do
      modules = subject.modules
      expect(modules[0].title).to eq 'hieradata'
      expect(modules[0].path).to eq Pathname.new('/some/nonexistent/environmentdir/prefix_release42/hieradata')

    end

    it "should support install_path" do
      modules = subject.modules
      expect(modules[1].title).to eq 'site_data_2'
      expect(modules[1].path).to eq Pathname.new('/some/nonexistent/environmentdir/prefix_release42/subdir/site_data_2')
    end

    context "with invalid configuration" do
      let(:subject_params) {{
      :modules => {
          'site_data_2' => {
            :type => 'git',
            :source => 'git@git.example.com:site_data.git',
            :install_path => '/absolute_path_outside_of_containing_environment'
          }
        }
      }}

      it "raises an error" do
        expect{ subject.modules }.to raise_error(R10K::Error, /Environment cannot.*outside of containing environment.*/i)
      end
    end
  end
end
