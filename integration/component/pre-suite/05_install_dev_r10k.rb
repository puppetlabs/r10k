test_name "Install PE r10k" do

  step "Install PE r10k" do

    # taken from beaker-pe/lib/beaker-pe/pe-client-tools/install_helper.rb
    install_dev_repos_on('pe-r10k', master, ENV['SHA'], '/tmp/repo_configs', {:dev_builds_url => 'http://builds.delivery.puppetlabs.net'})
    master.install_package('pe-r10k')

  end
end
