require 'digest'
require 'fileutils'
require 'find'
require 'minitar'
require 'net/http'
require 'tempfile'
require 'uri'
require 'zlib'
require 'r10k/settings'
require 'r10k/settings/mixin'
require 'r10k/util/platform'

module R10K
  class Tarball

    include R10K::Settings::Mixin

    def_setting_attr :proxy
    def_setting_attr :cache_root, if R10K::Util::Platform.windows?
                                    File.join(ENV['LOCALAPPDATA'], 'r10k', 'tarball')
                                  else
                                    File.expand_path(ENV['HOME'] ? '~/.r10k/tarball': '/root/.r10k/tarball')
                                  end

    # @!attribute [r] name
    #   @return [String] The tarball's name
    attr_accessor :name

    # @!attribute [r] source
    #   @return [String] The tarball's source
    attr_accessor :source

    # @!attribute [r] sha256digest
    #   @return [String] The tarball's expected sha256 digest
    attr_accessor :sha256digest

    # @param name [String] The name of the tarball content
    # @param source [String] The source for the tarball content
    # @param sha256digest [String] The sha256 digest of the tarball content
    def initialize(name, source, sha256digest: nil)
      @name = name
      @source = source
      @sha256digest = sha256digest
    end

    # @return [String] Directory. Where the cache will be created.
    def cache_root
      File.join(settings[:cache_root], sanitized_dirname(source))
    end

    # @return [String] File. The path the tarball will be cached to.
    def cache_path
      File.join(cache_root, tarball_basename)
    end

    # @return [String] The basename of the tarball cache file.
    def tarball_basename
      name + '.tar.gz'
    end

    # Extract the cached tarball to the target directory.
    #
    # @param target_dir [String] Where to unpack the tarball
    def unpack(target_dir)
      file = File.open(cache_path, 'rb')
      reader = Zlib::GzipReader.new(file)
      begin
        Minitar.unpack(reader, target_dir)
      ensure
        reader.close
      end
    end

    # @param target_dir [String] The directory to check if is insync with the
    #        tarball content
    #
    # @return [Boolean]
    def insync?(target_dir, purge: true)
      target_dir_entries = Find.find(target_dir).map(&:to_s) - [target_dir]
      each_tarball_entry do |entry|
        found = target_dir_entries.delete(File.join(target_dir, entry.full_name.chomp('/')))
        return false if found.nil?
        next if entry.directory?
        return false unless file_digest(found) == reader_digest(entry)
      end
      purge ? target_dir_entries.empty? : true
    end

    # Download the tarball from @source to @cache_path
    def download
      Dir.mktmpdir do
        tempfile = Tempfile.new(tarball_basename)
        tempfile.binmode
        src_uri = URI.parse(source)

        temp_digest = case src_uri.scheme
                      when 'file', nil
                        copy_to_file(src_uri.path, tempfile)
                      when %r{https?}
                        download_to_file(src_uri, tempfile)
                      else
                        raise "Unexpected source scheme #{src_uri.scheme}"
                      end

        # Verify the download
        unless (sha256digest == temp_digest) || sha256digest.nil?
          raise 'Downloaded file does not match digest'
        end

        # Move the download to cache_path
        FileUtils::mkdir_p(cache_root)
        begin
          FileUtils.mv(tempfile.path, cache_path)
        rescue Errno::EACCES
          FileUtils.cp(tempfile.path, cache_path)
        end

        tempfile.close
        tempfile.unlink
      end
    end

    # Is the cached tarball valid? Checks the cached tarball's digest against
    # the expected digest.
    #
    # @return [Boolean]
    def cache_valid?
      unless sha256digest.nil?
        File.exist?(cache_path) && sha256digest == file_digest(cache_path)
      else
        File.exist?(cache_path)
      end
    end

    # List all of the files contained in the tarball and their paths. This is
    # useful for implementing R10K::Purgable
    #
    # @return [Array] A list of file paths contained in the archive
    def paths
      names = Array.new
      each_tarball_entry { |entry| names << entry.full_name.chomp('/') }
      names
    end

    private

    CHUNK_SIZE = 64 * 1024 # 64 kb

    def each_tarball_entry(&block)
      File.open(cache_path, 'rb') do |file|
        Zlib::GzipReader.wrap(file) do |reader|
          Archive::Tar::Minitar::Input.each_entry(reader) do |entry|
            yield entry
          end
        end
      end
    end

    # Return the sha256 digest of the file at the given path
    #
    # @param path [String] The path to the file
    # @return [String] The file's sha256 hex digest
    def file_digest(path)
      File.open(path) do |file|
        reader_digest(file)
      end
    end

    # Return the sha256 digest of the readable data
    #
    # @param reader [String] An object that responds to #read
    # @return [String] The read data's sha256 hex digest
    def reader_digest(reader)
      digest = Digest::SHA256.new
      while chunk = reader.read(CHUNK_SIZE)
        digest.update(chunk)
      end

      digest.hexdigest
    end

    def sanitized_dirname(string)
      string.gsub(/[^@\w\.-]/, '-')
    end

    def http_get(uri, method: Net::HTTP::Get, redirect_limit: 10, &block)
      raise "HTTP redirect too deep" if redirect_limit.zero?
      request = method.new(uri)
      connection = Net::HTTP.new(uri.host, uri.port)

      proxy = if settings[:proxy]
                px = URI.parse(settings[:proxy])
                [px.host, px.port, px.user, px.password]
              else
                [nil, nil, nil, nil]
              end

      connection = Net::HTTP.new(uri.host, uri.port, *proxy)
      connection.use_ssl = true if uri.scheme == 'https'

      response = connection.start do |http|
        http.request(request) do |resp|
          case resp
          when Net::HTTPRedirection
            http_get(uri.merge(URI.parse(resp['location'])), redirect_limit: redirect_limit - 1, &block)
          when Net::HTTPSuccess
            yield resp
          else
            raise "Unexpected response code #{resp.code}: #{resp.read_body}"
          end
        end
      end
    end

    # @param input The file or path to copy from
    # @param output The file or path to copy to
    # @return [String] The copied file's sha256 hex digest
    def copy_to_file(input, output)
      digest = Digest::SHA256.new
      File.open(input, 'rb') do |input_stream|
        File.open(output, 'wb') do |output_stream|
          until input_stream.eof?
            chunk = input_stream.read(CHUNK_SIZE)
            output_stream.write(chunk)
            digest.update(chunk)
          end
        end
      end

      digest.hexdigest
    end

    # @param uri [URI] The URI to download from
    # @param output The file or path to save to
    # @return [String] The downloaded file's sha256 hex digest
    def download_to_file(uri, output)
      digest = Digest::SHA256.new
      http_get(uri) do |resp|
        File.open(output, 'wb') do |output_stream|
          resp.read_body do |chunk|
            output_stream.write(chunk)
            digest.update(chunk)
          end
        end
      end

      digest.hexdigest
    end
  end
end
