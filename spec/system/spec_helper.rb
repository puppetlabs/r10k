require 'rspec-system/spec_helper'
require 'rspec-system-serverspec/helpers'

require 'system/system-helpers'

require 'system-provisioning/el'

RSpec.configure do |c|

  include SystemProvisioning::EL

  def install_deps
    install_epel_release
    install_puppetlabs_release

    yum_install %w[ruby rubygems]
    yum_install %w[puppet]
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

  def purge_r10k
    shell 'gem uninstall -aIx r10k'
  end

  c.before(:suite) do
    purge_r10k
    install_deps
    name = build_artifact
    upload_artifact(name)
    install_artifact(name)
  end
end
