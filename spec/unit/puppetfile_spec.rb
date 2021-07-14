require 'spec_helper'
require 'r10k/puppetfile'

describe R10K::Puppetfile do

  subject do
    described_class.new(
      '/some/nonexistent/basedir',
      {puppetfile_name: 'Puppetfile.r10k'}
    )
  end

  describe "a custom puppetfile_name" do
    it "is the basedir joined with '/Puppetfile.r10k' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile.r10k'
    end
  end

end

describe R10K::Puppetfile do

  describe "a custom relative puppetfile_path" do
    it "is the basedir joined with the puppetfile_path" do
      relative_subject = described_class.new('/some/nonexistent/basedir',
                                             {puppetfile_path: 'relative/Puppetfile'})
      expect(relative_subject.puppetfile_path).to eq '/some/nonexistent/basedir/relative/Puppetfile'
    end
  end

  describe "a custom absolute puppetfile_path" do
    it "is the puppetfile_path as given" do
      absolute_subject = described_class.new('/some/nonexistent/basedir',
                                             {puppetfile_path: '/some/absolute/custom/Puppetfile'})
      expect(absolute_subject.puppetfile_path).to eq '/some/absolute/custom/Puppetfile'
    end
  end
end

describe R10K::Puppetfile do

  subject do
    described_class.new( '/some/nonexistent/basedir', {})
  end

  describe "backwards compatibility with older calling conventions" do
    it "honors all arguments correctly" do
      puppetfile = described_class.new('/some/nonexistant/basedir', '/some/nonexistant/basedir/site-modules', nil, 'Pupupupetfile', true)
      expect(puppetfile.force).to eq(true)
      expect(puppetfile.moduledir).to eq('/some/nonexistant/basedir/site-modules')
      expect(puppetfile.puppetfile_path).to eq('/some/nonexistant/basedir/Pupupupetfile')
      expect(puppetfile.overrides).to eq({})
    end

    it "handles defaults correctly" do
      puppetfile = described_class.new('/some/nonexistant/basedir', nil, nil, nil)
      expect(puppetfile.force).to eq(false)
      expect(puppetfile.moduledir).to eq('/some/nonexistant/basedir/modules')
      expect(puppetfile.puppetfile_path).to eq('/some/nonexistant/basedir/Puppetfile')
      expect(puppetfile.overrides).to eq({})
    end
  end

  describe "the default moduledir" do
    it "is the basedir joined with '/modules' path" do
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/modules'
    end
  end

  describe "the default puppetfile" do
    it "is the basedir joined with '/Puppetfile' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile'
    end
  end


  describe "setting moduledir" do
    it "changes to given moduledir if it is an absolute path" do
      subject.set_moduledir('/absolute/path/moduledir')
      expect(subject.moduledir).to eq '/absolute/path/moduledir'
    end

    it "joins the basedir with the given moduledir if it is a relative path" do
      subject.set_moduledir('relative/moduledir')
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/relative/moduledir'
    end
  end

  describe "loading a Puppetfile" do
    context 'using load' do
      it "returns the loaded content" do
        path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
        subject = described_class.new(path, {})

        loaded_content = subject.load
        expect(loaded_content).to be_an_instance_of(Hash)

        has_some_data = loaded_content.values.none?(&:empty?)
        expect(has_some_data).to be true
      end

      it "handles a relative basedir" do
        path = File.join('spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
        subject = described_class.new(path, {})

        loaded_content = subject.load
        expect(loaded_content).to be_an_instance_of(Hash)

        has_some_data = loaded_content.values.none?(&:empty?)
        expect(has_some_data).to be true
      end

      it "is idempotent" do
        path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
        subject = described_class.new(path, {})

        expect(subject.loader).to receive(:load!).and_call_original.once

        loaded_content1 = subject.load
        expect(subject.loaded?).to be true
        loaded_content2 = subject.load

        expect(loaded_content2).to eq(loaded_content1)
      end

      it "returns nil if Puppetfile doesn't exist" do
        path = '/rando/path/that/wont/exist'
        subject = described_class.new(path, {})
        expect(subject.load).to eq nil
      end
    end

    context 'using load!' do
      it "returns the loaded content" do
        path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
        subject = described_class.new(path, {})

        loaded_content = subject.load!
        expect(loaded_content).to be_an_instance_of(Hash)

        has_some_data = loaded_content.values.none?(&:empty?)
        expect(has_some_data).to be true
      end

      it "raises if Puppetfile doesn't exist" do
        path = '/rando/path/that/wont/exist'
        subject = described_class.new(path, {})
        expect {
          subject.load!
        }.to raise_error(/No such file or directory.*\/rando\/path\/.*/)
      end
    end
  end

  describe 'default_branch_override' do
    it 'is passed correctly to module loader init' do
      # This path doesn't matter so long as it has a Puppetfile within it
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
      subject = described_class.new(path, {overrides: {environments: {default_branch_override: 'foo'}}})

      repo = instance_double('R10K::Git::StatefulRepository')
      allow(repo).to receive(:resolve).with('foo').and_return(true)
      allow(R10K::Git::StatefulRepository).to receive(:new).and_return(repo)

      allow(subject.loader).to receive(:puppetfile_content).and_return <<-EOPF
        # Track control branch and fall-back to main if no matching branch.
        mod 'hieradata',
          :git => 'git@git.example.com:organization/hieradata.git',
          :branch => :control_branch,
          :default_branch => 'main'
        EOPF

      expect(subject.logger).not_to receive(:warn).
        with(/Mismatch between passed and initialized.*preferring passed value/)

      subject.load

      loaded_module = subject.modules.first
      expect(loaded_module.version).to eq('foo')
    end

    it 'overrides module loader init if needed' do
      # This path doesn't matter so long as it has a Puppetfile within it
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
      subject = described_class.new(path, {overrides: {environments: {default_branch_override: 'foo'}}})

      repo = instance_double('R10K::Git::StatefulRepository')
      allow(repo).to receive(:resolve).with('bar').and_return(true)
      allow(R10K::Git::StatefulRepository).to receive(:new).and_return(repo)

      allow(subject.loader).to receive(:puppetfile_content).and_return <<-EOPF
        # Track control branch and fall-back to main if no matching branch.
        mod 'hieradata',
          :git => 'git@git.example.com:organization/hieradata.git',
          :branch => :control_branch,
          :default_branch => 'main'
        EOPF

      expect(subject.logger).to receive(:warn).
        with(/Mismatch between passed and initialized.*preferring passed value/)

      subject.load('bar')
      loaded_module = subject.modules.first
      expect(loaded_module.version).to eq('bar')
    end

    it 'does not warn if passed and initialized default_branch_overrides match' do
      # This path doesn't matter so long as it has a Puppetfile within it
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
      subject = described_class.new(path, {overrides: {environments: {default_branch_override: 'foo'}}})

      repo = instance_double('R10K::Git::StatefulRepository')
      allow(repo).to receive(:resolve).with('foo').and_return(true)
      allow(R10K::Git::StatefulRepository).to receive(:new).and_return(repo)

      allow(subject.loader).to receive(:puppetfile_content).and_return <<-EOPF
        # Track control branch and fall-back to main if no matching branch.
        mod 'hieradata',
          :git => 'git@git.example.com:organization/hieradata.git',
          :branch => :control_branch,
          :default_branch => 'main'
        EOPF

      expect(subject.logger).not_to receive(:warn).
        with(/Mismatch between passed and initialized.*preferring passed value/)

      subject.load('foo')
      loaded_module = subject.modules.first
      expect(loaded_module.version).to eq('foo')
    end
  end

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:puppetfile, subject)
      subject.accept(visitor)
    end

    it "synchronizes each module if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :puppetfile
        expect(other).to eq subject
        block.call
      end

      mod1 = instance_double('R10K::Module::Base', :cachedir => :none)
      mod2 = instance_double('R10K::Module::Base', :cachedir => :none)
      expect(mod1).to receive(:sync)
      expect(mod2).to receive(:sync)
      expect(subject).to receive(:modules).and_return([mod1, mod2])

      subject.accept(visitor)
    end

    it "creates a thread pool to visit concurrently if pool_size setting is greater than one" do
      pool_size = 3

      subject.settings[:pool_size] = pool_size

      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :puppetfile
        expect(other).to eq subject
        block.call
      end

      mod1 = instance_double('R10K::Module::Base', :cachedir => :none)
      mod2 = instance_double('R10K::Module::Base', :cachedir => :none)
      expect(mod1).to receive(:sync)
      expect(mod2).to receive(:sync)
      expect(subject).to receive(:modules).and_return([mod1, mod2])

      expect(Thread).to receive(:new).exactly(pool_size).and_call_original
      expect(Queue).to receive(:new).and_call_original

      subject.accept(visitor)
    end

    it "Creates queues of modules grouped by cachedir" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :puppetfile
        expect(other).to eq subject
        block.call
      end

      m1 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/A')
      m2 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/B')
      m3 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/C')
      m4 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/C')
      m5 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/D')
      m6 = instance_double('R10K::Module::Base', :cachedir => '/dev/null/D')

      modules = [m1, m2, m3, m4, m5, m6]

      queue = R10K::ContentSynchronizer.modules_visit_queue(modules, visitor, subject)
      expect(queue.length).to be 4
      queue_array = 4.times.map { queue.pop }
      expect(queue_array).to match_array([[m1], [m2], [m3, m4], [m5, m6]])
    end
  end
end
