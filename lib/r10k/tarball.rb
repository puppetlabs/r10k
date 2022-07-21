require 'fileutils'
require 'find'
require 'minitar'
require 'tempfile'
require 'uri'
require 'zlib'
require 'r10k/settings'
require 'r10k/settings/mixin'
require 'r10k/util/platform'
require 'r10k/util/cacheable'
require 'r10k/util/downloader'

module R10K
  class Tarball

    include R10K::Settings::Mixin
    include R10K::Util::Cacheable
    include R10K::Util::Downloader
    include R10K::Logging

    # Filenames which are considered headers that might be added to a tarball,
    # but which are not to be counted against the check for a wrapper dir. When
    # wrapper dirs are removed, these files will not be unpacked.
    WRAPPER_HEADER_FILES = ['pax_global_header']

    def_setting_attr :proxy      # Defaults to global proxy setting
    def_setting_attr :cache_root, R10K::Util::Cacheable.default_cachedir

    # @!attribute [rw] name
    #   @return [String] The tarball's name
    attr_accessor :name

    # @!attribute [rw] source
    #   @return [String] The tarball's source
    attr_accessor :source

    # @!attribute [rw] checksum
    #   @return [String] The tarball's expected sha256 digest
    attr_accessor :checksum

    # @!attribute [rw] remove_wrapper_dir
    #   @return [Boolean] Whether or not the tarball removes the wrapper
    #           directory from the tarball source when extracting or verifying
    #           unpacked content
    attr_accessor :remove_wrapper_dir

    # @param name [String] The name of the tarball content
    # @param source [String] The source for the tarball content
    # @param checksum [String] The sha256 digest of the tarball content
    # @param remove_wrapper_dir [Boolean] Whether or not the tarball should
    #        remove the wrapper directory from the tarball source when
    #        extracting or verifying unpacked content
    def initialize(name, source, checksum: nil, remove_wrapper_dir: false)
      @name = name
      @source = source
      @checksum = checksum
      @remove_wrapper_dir = remove_wrapper_dir
      @wrapper_dir = nil

      # At this time, the only checksum type supported is sha256. In the future,
      # we may decide to support other algorithms if a use case arises. TBD.
      checksum_algorithm = :SHA256
    end

    # @return [String] Directory. Where the cache_basename file will be created.
    def cache_dirname
      File.join(settings[:cache_root], 'tarball')
    end

    # The final cache_path should match one of the templates:
    #
    #   - {cachedir}/{checksum}.tar.gz
    #   - {cachedir}/{source}.tar.gz
    #
    # @return [String] File. The full file path the tarball will be cached to.
    def cache_path
      File.join(cache_dirname, cache_basename)
    end

    # @return [String] The basename of the tarball cache file.
    def cache_basename
      if checksum.nil?
        sanitized_dirname(source) + '.tar.gz'
      else
        checksum + '.tar.gz'
      end
    end

    # Extract the cached tarball to the target directory.
    #
    # @param target_dir [String] Where to unpack the tarball
    def unpack(dest)
      # Important to make sure this is an absolute path, since we may be
      # chdir'ing later
      dest = File.expand_path(dest)

      file = File.open(cache_path, 'rb')
      reader = Zlib::GzipReader.new(file)

      begin
        if remove_wrapper_dir

          # Minitar doesn't provide a great facility for stripping a wrapper
          # dir out. Rather than re-implement most of Minitar#unpack to do
          # that, the strategy is:
          #  1. Create the dest dir.
          #  2. Create a tempdir inside the dest directory.
          #  3. Unpack the tarball into the tempdir using Minitar#unpack.
          #  3. The tempdir now contains the extracted wrapper dir. Move all
          #     files and directories from the wrapper dir to the dest dir.
          #  4. Delete the tempdir.
          FileUtils.mkdir_p(dest) unless File.exist?(dest)
          Dir.mktmpdir('unpack-', dest) do |tmpdir|
            Minitar.unpack(reader, tmpdir)
            Dir.chdir(File.join(tmpdir, wrapper_dir)) do
              FileUtils.mv(paths.reject { |p| p.include?('/') }, dest, force: true)
            end
          end

        else
          Minitar.unpack(reader, dest)
        end
      ensure
        reader.close
      end

      nil
    end

    # @param target_dir [String] The directory to check if is in sync with the
    #        tarball content
    # @param ignore_untracked_files [Boolean] If true, consider the target
    #        dir to be in sync as long as all tracked content matches.
    # @param remove_wrapper_dir [Boolean] Whether or not to remove the wrapper
    #        directory from the content when comparing to the target_dir
    #
    # @return [Boolean]
    def insync?(target_dir, ignore_untracked_files: false)
      target_tree_entries = Find.find(target_dir).map(&:to_s) - [target_dir]
      name = nil

      each_tarball_entry do |entry|
        if remove_wrapper_dir
          name = clean_full_name(entry).sub(%r{\A#{Regexp.escape(wrapper_dir)}/}, '')
          next if [wrapper_dir, *WRAPPER_HEADER_FILES].include?(name)
        else
          name = entry.full_name
        end

        found = target_tree_entries.delete(File.join(target_dir, name.chomp('/')))
        return false if found.nil?
        next if entry.directory?
        return false unless file_digest(found) == reader_digest(entry)
      end

      if ignore_untracked_files
        # We wouldn't have gotten this far if there were discrepancies in
        # tracked content
        true
      else
        # If there are still files in target_tree_entries, then there is
        # untracked content present in the target tree. If not, we're in sync.
        target_tree_entries.empty?
      end
    end

    # Download the tarball from @source to @cache_path
    def get
      # Clear any calculated information about the tarball
      @wrapper_dir = nil

      Tempfile.open(cache_basename) do |tempfile|
        tempfile.binmode
        src_uri = URI.parse(source)

        temp_digest = case src_uri.scheme
                      when 'file', nil
                        copy(src_uri.path, tempfile)
                      when %r{^[a-z]$} # Windows drive letter
                        copy(src_uri.to_s, tempfile)
                      when %r{^https?$}
                        download(src_uri, tempfile)
                      else
                        raise "Unexpected source scheme #{src_uri.scheme}"
                      end

        # Verify the download
        unless (checksum == temp_digest) || checksum.nil?
          raise 'Downloaded file does not match checksum'
        end

        # Move the download to cache_path
        FileUtils::mkdir_p(cache_dirname)
        begin
          FileUtils.mv(tempfile.path, cache_path)
        rescue Errno::EACCES
          # It may be the case that permissions don't permit moving the file
          # into place, but do permit overwriting an existing in-place file.
          FileUtils.cp(tempfile.path, cache_path)
        end
      end
    end

    # Checks the cached tarball's digest against the expected checksum. Returns
    # false if no cached file is present. If the tarball has no expected
    # checksum, any cached file is assumed to be valid.
    #
    # @return [Boolean]
    def cache_valid?
      return false unless File.exist?(cache_path)
      return true if checksum.nil?
      checksum == file_digest(cache_path)
    end

    # List all of the files contained in the tarball and their paths, as
    # R10K::Tarball will unpack them. This is useful for implementing
    # R10K::Purgable
    #
    # @return [Array] A normalized list of file paths as they will be
    #         extracted from the archive
    def paths
      if remove_wrapper_dir
        cleanpaths.map { |n| n.sub(%r{\A#{Regexp.escape(wrapper_dir)}/}, '') } - [wrapper_dir, *WRAPPER_HEADER_FILES]
      else
        cleanpaths
      end
    end

    # Return the name of the wrapper directory containing all other paths in the taball
    #
    # @return [String] The name of the wrapper directory
    # @raise [StandardError] if the tarball does not contain a wrapper directory
    def wrapper_dir
      return @wrapper_dir unless @wrapper_dir.nil?
      paths = cleanpaths - WRAPPER_HEADER_FILES
      shortest = paths.sort_by { |p| p.length }.first

      unless (paths - [shortest]).all? { |p| p.start_with?(shortest + '/') }
        logger.debug "Tarball paths: #{cleanpaths}"
        raise 'Tarball content does not have a wrapper directory! ' \
              'It should contain all content in a single wrapper directory. ' \
              'E.g. "puppetlabs-stdlib-7.1.0/*", or "my-env-g826ab83/*"'
      end

      @wrapper_dir = shortest
    end

    def cache_checksum
      raise R10K::Error, _("Cache not present at %{path}") % {path: cache_path} unless File.exist?(cache_path)
      file_digest(cache_path)
    end

    private

    # List all the (cleaned) paths contained in the tarball, as the tarball
    # lists them. Not subject to the remove_wrapper_dir setting, or any other
    # adjustments R10K::Tarball might make when it unpacks them.
    def cleanpaths
      each_tarball_entry.map { |entry| clean_full_name(entry) } - ['.']
    end

    # Return an entry's clean path name, with things like "./" prefixes or
    # repeated "." and ".." sequences removed.
    #
    # @param entry [Archive::Tar::Minitar::Reader::EntryStream]
    def clean_full_name(entry)
      Pathname.new(entry.full_name).cleanpath.to_s
    end

    def each_tarball_entry(&block)
      File.open(cache_path, 'rb') do |file|
        Zlib::GzipReader.wrap(file) do |reader|
          Archive::Tar::Minitar::Input.each_entry(reader) do |entry|
            return to_enum :each_tarball_entry unless block_given?
            yield entry
          end
        end
      end
    end
  end
end
