require 'r10k/hg/cache'
require 'r10k/hg/errors'
require 'r10k/hg/repository'
require 'forwardable'
require 'r10k/logging'

# Manage how Mecurial repositories are created and set to specific revisions
class R10K::Hg::StatefulRepository

  include R10K::Logging

  # @!attribute [r] repo
  #   @api private
  attr_reader :repo

  extend Forwardable
  def_delegators :@repo, :head

  # Create a new Mecurial working directory
  #
  # @param rev     [String] The Mecurial revision to check out
  # @param remote  [String] The Mecurial remote to use for the repo
  # @param basedir [String] The path containing the Mecurial repo
  # @param dirname [String] The directory name of the Mecurial repo
  def initialize(rev, remote, basedir, dirname, options = {})
    @rev = rev
    @remote = remote

    @cache = R10K::Hg::Cache.generate(remote)

    case options[:ref_type]
      when :branch
        repo_options = {
            :clone => {:branch => rev},
            :pull => {:branch => rev}
        }
      when :bookmark
        repo_options = {
            :clone => {:rev => rev},
            :pull => {:bookmark => rev}
        }
      else
        repo_options = {
            :clone => {:rev => rev},
            :pull => {:rev => rev}
        }
    end

    @repo = R10K::Hg::Repository.new(basedir, dirname, repo_options)
  end

  def sync
    @cache.sync if sync_cache?

    sha = @cache.resolve(@rev)

    if sha.nil?
      raise R10K::Hg::UnknownRevisionError.new("Unable to sync repo to unresolvable revision '#{@rev}'", path => path)
    end

    case status
      when :absent
        logger.debug { "Cloning #{@repo.path} and checking out #{@rev}" }
        @repo.clone(@cache.path.to_s, {:rev => sha})
        @repo.add_path('origin', @remote)
      when :mismatched
        logger.debug { "Replacing #{@repo.path} and checking out #{@rev}" }
        @repo.path.rmtree
        @repo.clone(@cache.path.to_s, {:rev => sha})
        @repo.add_path('origin', @remote)
      when :outdated
        logger.debug { "Updating #{@repo.path} to #{@rev}" }
        @repo.fetch
        @repo.checkout(sha)
      else
        logger.debug { "#{@repo.path} is already at revision #{@rev}" }
    end
  end

  def status
    if !@repo.exist?
      :absent
    elsif !@repo.path.exist?
      :mismatched
    elsif !@repo.path.directory?
      :mismatched
    elsif !(@repo.resolve_path('origin') == @remote)
      :mismatched
    elsif !(@repo.head == @cache.resolve(@rev))
      :outdated
    elsif [:branch, :bookmark].include? @cache.ref_type(@rev) && !@cache.synced?
      :outdated
    else
      :insync
    end
  end

  # @api private
  def sync_cache?
    return true if !@cache.exist?
    return true if !@cache.resolve(@rev)
    return true if !([:changeset, :tag].include? @cache.ref_type(@rev))
    return false
  end
end
