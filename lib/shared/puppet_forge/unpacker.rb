require 'pathname'
require 'shared/puppet_forge/error'
require 'shared/puppet_forge/tar'

module PuppetForge
  class Unpacker
    # Unpack a tar file into a specified directory
    #
    # @param filename [String] the file to unpack
    # @param target [String] the target directory to unpack into
    # @return [Hash{:symbol => Array<String>}] a hash with file-category keys pointing to lists of filenames.
    #   The categories are :valid, :invalid and :symlink
    def self.unpack(filename, target, tmpdir)
      inst = self.new(filename, target, tmpdir)
      file_lists = inst.unpack
      inst.move_into(Pathname.new(target))
      file_lists
    end

    # Set the owner/group of the target directory to those of the source
    # Note: don't call this function on Microsoft Windows
    #
    # @param source [Pathname] source of the permissions
    # @param target [Pathname] target of the permissions change
    def self.harmonize_ownership(source, target)
        FileUtils.chown_R(source.stat.uid, source.stat.gid, target)
    end

    # @param filename [String] the file to unpack
    # @param target [String] the target directory to unpack into
    def initialize(filename, target, tmpdir)
      @filename = filename
      @target = target
      @tmpdir = tmpdir
    end

    # @api private
    def unpack
      begin
        PuppetForge::Tar.instance.unpack(@filename, @tmpdir)
      rescue PuppetForge::ExecutionFailure => e
        raise RuntimeError, "Could not extract contents of module archive: #{e.message}"
      end
    end

    # @api private
    def move_into(dir)
      dir.rmtree if dir.exist?
      FileUtils.mv(root_dir, dir)
    ensure
      FileUtils.rmtree(@tmpdir)
    end

    # @api private
    def root_dir
      return @root_dir if @root_dir

      # Grab the first directory containing a metadata.json file
      metadata_file = Dir["#{@tmpdir}/**/metadata.json"].sort_by(&:length)[0]

      if metadata_file
        @root_dir = Pathname.new(metadata_file).dirname
      else
        raise "No valid metadata.json found!"
      end
    end
  end
end
