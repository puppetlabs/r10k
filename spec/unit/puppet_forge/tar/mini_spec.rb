require 'shared/puppet_forge/tar/mini'
require 'shared/puppet_forge/error'


describe PuppetForge::Tar::Mini do
  let(:entry_class) do
    Class.new do
      attr_accessor :typeflag, :name
      def initialize(name, typeflag)
        @name = name
        @typeflag = typeflag
      end
    end
  end
  let(:sourcefile) { '/the/module.tar.gz' }
  let(:destdir)    { File.expand_path '/the/dest/dir' }
  let(:sourcedir)  { '/the/src/dir' }
  let(:destfile)   { '/the/dest/file.tar.gz' }
  let(:minitar)    { described_class.new }
  let(:tarfile_contents) { [entry_class.new('file', '0'), \
                            entry_class.new('symlink', '2'), \
                            entry_class.new('invalid', 'F')] }

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

  it "returns filenames in a tar separated into correct categories" do
    reader = double('GzipReader')

    expect(Zlib::GzipReader).to receive(:open).with(sourcefile).and_yield(reader)
    expect(Archive::Tar::Minitar).to receive(:open).with(reader).and_return(tarfile_contents)
    expect(Archive::Tar::Minitar).to receive(:unpack).with(reader, destdir, ['file']).and_yield(:file_start, 'thefile', nil)
    
    file_lists = minitar.unpack(sourcefile, destdir)

    expect(file_lists[:valid]).to eq(['file'])
    expect(file_lists[:invalid]).to eq(['invalid'])
    expect(file_lists[:symlinks]).to eq(['symlink'])
  end

  def unpacks_the_entry(type, name)
    reader = double('GzipReader')

    expect(Zlib::GzipReader).to receive(:open).with(sourcefile).and_yield(reader)
    expect(minitar).to receive(:validate_files).with(reader).and_return({:valid => [name]})
    expect(Archive::Tar::Minitar).to receive(:unpack).with(reader, destdir, [name]).and_yield(type, name, nil)
  end
end
