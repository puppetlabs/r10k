require 'json'
require 'tmpdir'
require 'shared/puppet_forge/unpacker'

describe PuppetForge::Unpacker do

  let(:source)      { Dir.mktmpdir("source") }
  let(:target)      { Dir.mktmpdir("unpacker") }
  let(:module_name) { 'myusername-mytarball' }
  let(:filename)    { Dir.mktmpdir("module") + "/module.tar.gz" }
  let(:working_dir) { Dir.mktmpdir("working_dir") }
  let(:trash_dir)   { Dir.mktmpdir("trash_dir") }

  it "attempts to untar file to temporary location" do

    minitar = double('PuppetForge::Tar::Mini')

    expect(minitar).to receive(:unpack).with(filename, anything()) do |src, dest|
      FileUtils.mkdir(File.join(dest, 'extractedmodule'))
      File.open(File.join(dest, 'extractedmodule', 'metadata.json'), 'w+') do |file|
        file.puts JSON.generate('name' => module_name, 'version' => '1.0.0')
      end
      true
    end

    expect(PuppetForge::Tar).to receive(:instance).and_return(minitar)
    PuppetForge::Unpacker.unpack(filename, target, trash_dir)
    expect(File).to be_directory(target)
  end

  it "attempts to set the ownership of a target dir to a source dir's owner" do

    source_path = Pathname.new(source)
    target_path = Pathname.new(target)

    expect(FileUtils).to receive(:chown_R).with(source_path.stat.uid, source_path.stat.gid, target_path)

    PuppetForge::Unpacker.harmonize_ownership(source_path, target_path)
  end

end
