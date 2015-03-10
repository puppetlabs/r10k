require 'r10k/deployment'
require 'r10k/logging'
require 'r10k/util/purgeable'

module R10K
  module Util

    # Represents a directory that can purge unmanaged contents
    #
    # @todo pick a better name than basedir. Expect this class to be renamed.
    #
    # @api private
    class Basedir

      include R10K::Util::Purgeable
      include R10K::Logging

      # Create a new Basedir by selecting sources from a deployment that match
      # the specified path.
      #
      # @param path [String]
      # @param deployment [R10K::Deployment]
      #
      # @return [R10K::Util::Basedir]
      def self.from_deployment(path, deployment)
        sources = deployment.sources.select { |source| source.managed_directory == path }
        new(path, sources)
      end

      # @param path [String] The path to the directory to manage
      # @param sources [Array<#desired_contents>] A list of objects that may create filesystem entries
      def initialize(path, sources)
        if sources.is_a? R10K::Deployment
          raise ArgumentError, "Expected Array<#desired_contents>, got R10K::Deployment"
        end
        @path    = path
        @sources = sources
      end

      # Return the path of the basedir
      # @note This implements a required method for the Purgeable mixin
      # @return [String]
      def managed_directory
        @path
      end

      # List all environments that should exist in this basedir
      # @note This implements a required method for the Purgeable mixin
      # @return [Array<String>]
      def desired_contents
        @sources.map(&:desired_contents).flatten
      end

      def purge!
        @sources.each do |source|
          logger.debug1 "Source #{source.name} in #{@path} claimed contents #{source.desired_contents.inspect}"
        end
        if !stale_contents.empty?
          logger.debug "No sources in #{@path} claimed contents #{stale_contents.inspect}"
        end
        super
      end
    end
  end
end
