require 'shared/puppet_forge/tar/mini'
require 'shared/puppet_forge/error'


describe PuppetForge::Tar::Mini do
  let(:sourcefile) { '/the/module.tar.gz' }
  let(:destdir)    { File.expand_path '/the/dest/dir' }
  let(:sourcedir)  { '/the/src/dir' }
  let(:destfile)   { '/the/dest/file.tar.gz' }
  let(:minitar)    { described_class.new }

  it "unpacks a tar file" do
    unpacks_the_entry(:file_start, 'thefile')

    minitar.unpack(sourcefile, destdir)
  end

  it "does not allow an absolute path" do
    unpacks_the_entry(:file_start, '/thefile')

    expect {
      minitar.unpack(sourcefile, destdir)
    }.to raise_error(PuppetForge::InvalidPathInPackageError,
                     "Attempt to install file into \"/thefile\" under \"#{destdir}\"")
  end

  it "does not allow a file to be written outside the destination directory" do
    unpacks_the_entry(:file_start, '../../thefile')

    expect {
      minitar.unpack(sourcefile, destdir)
    }.to raise_error(PuppetForge::InvalidPathInPackageError,
                     "Attempt to install file into \"#{File.expand_path('/the/thefile')}\" under \"#{destdir}\"")
  end

  it "does not allow a directory to be written outside the destination directory" do
    unpacks_the_entry(:dir, '../../thedir')

    expect {
      minitar.unpack(sourcefile, destdir)
    }.to raise_error(PuppetForge::InvalidPathInPackageError,
                     "Attempt to install file into \"#{File.expand_path('/the/thedir')}\" under \"#{destdir}\"")
  end

  it "packs a tar file" do
    writer = double('GzipWriter')

    expect(Zlib::GzipWriter).to receive(:open).with(destfile).and_yield(writer)
    expect(Archive::Tar::Minitar).to receive(:pack).with(sourcedir, writer)

    minitar.pack(sourcedir, destfile)
  end

  def unpacks_the_entry(type, name)
    reader = double('GzipReader')

    expect(Zlib::GzipReader).to receive(:open).with(sourcefile).and_yield(reader)
    expect(minitar).to receive(:find_valid_files).with(reader).and_return([name])
    expect(Archive::Tar::Minitar).to receive(:unpack).with(reader, destdir, [name]).and_yield(type, name, nil)
  end
end
