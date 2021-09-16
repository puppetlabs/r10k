require 'digest'
require 'net/http'

module R10K
  module Util

    # Utility mixin for classes that need to download files
    module Downloader

      private

      CHUNK_SIZE = 64 * 1024 # 64 kb

      # @param src_uri [URI] The URI to download from
      # @param dst_file [String] The file or path to save to
      # @param checksum_algorithm [Symbol] The Digest algorithm to use
      # @return [String] The downloaded file's hex digest
      def download(src_uri, dst_file, checksum_algorithm = :SHA256)
        digest = Digest(checksum_algorithm).new
        http_get(src_uri) do |resp|
          File.open(dst_file, 'wb') do |output_stream|
            resp.read_body do |chunk|
              output_stream.write(chunk)
              digest.update(chunk)
            end
          end
        end

        digest.hexdigest
      end

      # @param input The file or path to copy from
      # @param output The file or path to copy to
      # @return [String] The copied file's sha256 hex digest
      def copy(src_file, dst_file, checksum_algorithm = :SHA256)
        digest = Digest(checksum_algorithm).new
        File.open(src_file, 'rb') do |input_stream|
          File.open(dst_file, 'wb') do |output_stream|
            until input_stream.eof?
              chunk = input_stream.read(CHUNK_SIZE)
              output_stream.write(chunk)
              digest.update(chunk)
            end
          end
        end

        digest.hexdigest
      end

      # Start a Net::HTTP::Get connection, then yield the Net::HTTPSuccess object
      # to the caller's block. Follow redirects if Net::HTTPRedirection responses
      # are encountered, and honor settings[:proxy].
      def http_get(uri, redirect_limit: 10, &block)
        raise "HTTP redirect too deep" if redirect_limit.zero?

        connection = Net::HTTP.new(uri.host, uri.port, *proxy_to_array(settings[:proxy]))
        connection.use_ssl = true if uri.scheme == 'https'

        session = connection.start
        begin
          session.request_get(uri) do |response|
            case response
            when Net::HTTPRedirection
              redirect = response['location']
              session.finish
              return http_get(URI.parse(redirect), redirect_limit: redirect_limit - 1, &block)
            when Net::HTTPSuccess
              yield response
            else
              raise "Unexpected response code #{response.code}: #{response}"
            end
          end
        ensure
          session.finish if session.active?
        end
      end

      # Helper method to translate a proxy URI to array arguments for
      # Net::HTTP#new. A nil argument returns nil array elements.
      def proxy_to_array(proxy_uri)
        if proxy_uri
          px = URI.parse(settings[:proxy])
          [px.host, px.port, px.user, px.password]
        else
          [nil, nil, nil, nil]
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
        digest = Digest(checksum_algorithm).new
        while chunk = reader.read(CHUNK_SIZE)
          digest.update(chunk)
        end

        digest.hexdigest
      end
    end
  end
end
