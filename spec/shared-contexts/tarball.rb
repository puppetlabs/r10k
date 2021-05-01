require 'tmpdir'
require 'fileutils'

shared_context "Tarball" do
  # Suggested subject:
  #
  #   subject { described_class.new('fixture-tarball', fixture_tarball, checksum: fixture_checksum) }
  #
  let(:fixture_tarball) do
    File.expand_path('spec/fixtures/tarball/tarball.tar.gz', PROJECT_ROOT)
  end

  let(:fixture_checksum) { '292e692ad18faabd4f9b21037d51f0185e04b69f82c522a54af91fb5b88c2d3b' }

  # Use tmpdir for cached tarballs
  let(:tmpdir) { Dir.mktmpdir }

  # `moduledir` and `cache_root` are available for examples to use in creating
  # their subjects
  let(:moduledir) { File.join(tmpdir, 'modules').tap { |path| Dir.mkdir(path) } }
  let(:cache_root) { File.join(tmpdir, 'cache').tap { |path| Dir.mkdir(path) } }

  around(:each) do |example|
    if subject.is_a?(R10K::Tarball)
      subject.settings[:cache_root] = cache_root
    elsif subject.respond_to?(:tarball) && subject.tarball.is_a?(R10K::Tarball)
      subject.tarball.settings[:cache_root] = cache_root
    end
    example.run
    FileUtils.remove_entry_secure(tmpdir)
  end
end
