require 'rspec-system/spec_helper'
require 'rspec-system-serverspec/helpers'

RSpec.configure do |c|
  def install_rubygems
    shell 'rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm'
    shell 'rpm -Uvh http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm'
    shell 'yum -y install rubygems'
    shell 'yum -y install puppet'
  end

  def build_artifact
    require 'r10k/version'

    desc = %x{git describe}.chomp
    artifact_name = "r10k-#{desc}.gem"

    system('gem build r10k.gemspec')
    FileUtils.mv "r10k-#{R10K::VERSION}.gem", artifact_name

    artifact_name
  end

  def upload_artifact(name)
    rcp :sp => "./#{name}", :dp => '/root'
  end

  def install_artifact(name)
    shell "gem install --no-rdoc --no-ri /root/#{name}"
    shell "rm /root/#{name}"
  end

  def purge_gems
    shell 'gem list | cut -d" " -f1 | xargs gem uninstall -aIx'
  end

  c.before(:suite) do
    purge_gems
    install_rubygems
    name = build_artifact
    upload_artifact(name)
    install_artifact(name)
  end
end
