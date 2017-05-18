test_name "Install PE r10k" do

  step "Install PE r10k" do

    install_pe_product_on(master, 'pe-r10k', ENV['SHA'])

  end
end

# taken from beaker-pe/lib/beaker-pe/pe-client-tools/install_helper.rb
def install_pe_product_on(hosts, product, product_sha)

    block_on hosts do |host|
      variant, version, arch, codename = host['platform'].to_array
        install_dev_repos_on(product, host, product_sha, '/tmp/repo_configs', {:dev_builds_url => 'http://builds.delivery.puppetlabs.net'})
        host.install_package(product)
    end
  end
