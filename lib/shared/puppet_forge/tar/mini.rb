require 'zlib'
require 'archive/tar/minitar'

module PuppetForge
  class Tar
    class Mini

      SYMLINK_FLAG = 2
      VALID_TAR_FLAGS = (0..7)

      def unpack(sourcefile, destdir)
        dirlist = []
        Zlib::GzipReader.open(sourcefile) do |reader|
          Archive::Tar::Minitar.unpack(reader, destdir, find_valid_files(reader)) do |action, name, stats|
            case action
            when :file_done
              FileUtils.chmod('u+rw,g+r,a-st', "#{destdir}/#{name}")
            when :file_start
              validate_entry(destdir, name)
            when :dir
              validate_entry(destdir, name)
              dirlist << "#{destdir}/#{name}"
            end
          end
        end
        dirlist.each {|d| File.chmod(0755, d)}
      end

      def pack(sourcedir, destfile)
        Zlib::GzipWriter.open(destfile) do |writer|
          Archive::Tar::Minitar.pack(sourcedir, writer)
        end
      end

      private

      # Find all the valid files in tarfile.
      #
      # Symlinks are not supported in modules
      #
      # This check was mainly added to ignore 'x' and 'g' flags from the PAX
      # standard but will also ignore any other non-standard tar flags.
      # tar format info: http://pic.dhe.ibm.com/infocenter/zos/v1r13/index.jsp?topic=%2Fcom.ibm.zos.r13.bpxa500%2Ftaf.htm
      # pax format info: http://pic.dhe.ibm.com/infocenter/zos/v1r13/index.jsp?topic=%2Fcom.ibm.zos.r13.bpxa500%2Fpxarchfm.htm
      def find_valid_files(tarfile)
        Archive::Tar::Minitar.open(tarfile).collect do |entry|
          flag = entry.typeflag
          # Symlinks are not supported in modules and a warning is issued (flag '2' is a symlink)
          if flag.nil? || flag =~ /[[:digit:]]/ && SYMLINK_FLAG == flag.to_i
            # TODO: Error/Warn about symlinks here.
            entry.name
          elsif flag.nil? || flag =~ /[[:digit:]]/ && VALID_TAR_FLAGS.include?(flag.to_i)
            entry.name
          else
            next
          end
        end
      end

      def validate_entry(destdir, path)
        if Pathname.new(path).absolute?
          raise PuppetForge::InvalidPathInPackageError, :entry_path => path, :directory => destdir
        end

        path = File.expand_path File.join(destdir, path)

        if path !~ /\A#{Regexp.escape destdir}/
          raise PuppetForge::InvalidPathInPackageError, :entry_path => path, :directory => destdir
        end
      end
    end
  end

end

