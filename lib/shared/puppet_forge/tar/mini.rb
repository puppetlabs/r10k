require 'zlib'
require 'archive/tar/minitar'

module PuppetForge
  class Tar
    class Mini

      SYMLINK_FLAGS = [2]
      VALID_TAR_FLAGS = (0..7)

      # @return [Hash{:symbol => Array<String>}] a hash with file-category keys pointing to lists of filenames.
      def unpack(sourcefile, destdir)
        # directories need to be changed outside of the Minitar::unpack because directories don't have a :file_done action
        dirlist = []
        file_lists = {}
        Zlib::GzipReader.open(sourcefile) do |reader|
          file_lists = validate_files(reader)
          Archive::Tar::Minitar.unpack(reader, destdir, file_lists[:valid]) do |action, name, stats|
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
        file_lists
      end

      def pack(sourcedir, destfile)
        Zlib::GzipWriter.open(destfile) do |writer|
          Archive::Tar::Minitar.pack(sourcedir, writer)
        end
      end

      private

      # Categorize all the files in tarfile as :valid, :invalid, or :symlink.
      #
      # :invalid files include 'x' and 'g' flags from the PAX standard but and any other non-standard tar flags.
      #   tar format info: http://pic.dhe.ibm.com/infocenter/zos/v1r13/index.jsp?topic=%2Fcom.ibm.zos.r13.bpxa500%2Ftaf.htm
      #   pax format info: http://pic.dhe.ibm.com/infocenter/zos/v1r13/index.jsp?topic=%2Fcom.ibm.zos.r13.bpxa500%2Fpxarchfm.htm
      # :symlinks are not supported in Puppet modules
      # :valid files are any of those that can be used in modules
      # @param tarfile name of the tarfile
      # @return [Hash{:symbol => Array<String>}] a hash with file-category keys pointing to lists of filenames.
      def validate_files(tarfile)
        file_lists = {:valid => [], :invalid => [], :symlinks => []}
        Archive::Tar::Minitar.open(tarfile).each do |entry|
          flag = entry.typeflag
          if flag.nil? || flag =~ /[[:digit:]]/ && SYMLINK_FLAGS.include?(flag.to_i)
            file_lists[:symlinks] << entry.name
          elsif flag.nil? || flag =~ /[[:digit:]]/ && VALID_TAR_FLAGS.include?(flag.to_i)
            file_lists[:valid] << entry.name
          else
            file_lists[:invalid] << entry.name 
          end
        end
        file_lists
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

