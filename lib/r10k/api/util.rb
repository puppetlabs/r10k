require 'r10k/api/git'

module R10K
  module API
    # R10K::API Utility methods.
    #
    # @api private
    module Util
      def git
        R10K::API::Git
      end

      def default_cachedir
        File.expand_path(ENV['HOME'] ? '~/.r10k': '/root/.r10k')
      end

      def default_moduledir
        "modules"
      end

      def cachedir_for_git_remote(remote, cachedir=nil)
        cachedir ||= default_cachedir
        repo_path = remote.gsub(/[^@\w\.-]/, '-').gsub(/^-+/, '')

        return File.join(cachedir, 'git', repo_path)
      end

      def cachedir_for_forge_module(module_slug, cachedir=nil)
        cachedir ||= default_cachedir

        return File.join(cachedir, 'forge', module_slug)
      end

      def module_slug_from_release_slug(release_slug)
        return release_slug.split('-')[0..-2].join('-')
      end

      def release_slug_from_module_slug_version(module_slug, version)
        return [module_slug, version].join('-')
      end

      def self.extended(receiver)
        receiver.class_eval do
          private_class_method :git
          private_class_method :default_cachedir
          private_class_method :default_moduledir
          private_class_method :cachedir_for_git_remote
          private_class_method :cachedir_for_forge_module
        end
      end
    end
  end
end
