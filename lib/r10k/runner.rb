require 'r10k'
require 'r10k/root'
require 'r10k/synchro/git'
require 'yaml'

class R10K::Runner

  def run
    roots.each do |root|
      root.sync!

      root.modules.each do |mod|
        mod.sync!
      end
    end
  end

  def common_root
    @base ||= R10K::Root.new(
      config[:basedir],
      config[:installdir],
      config[:baserepo],
      'master')
  end
end
