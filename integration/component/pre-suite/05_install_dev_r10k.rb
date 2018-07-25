test_name "Install PE r10k" do

  step "Install PE r10k" do
    variant, version, arch, codename = master['platform'].to_array
    if variant == 'ubuntu' && version.split('.').first.to_i >= 18
      on master, "echo 'Acquire::AllowInsecureRepositories \"true\";' > /etc/apt/apt.conf.d/90insecure"
    end

    install_dev_repos_on('pe-r10k', master, ENV['SHA'], '/tmp/repo_configs', {:dev_builds_url => 'http://builds.delivery.puppetlabs.net'})
    master.install_package('pe-r10k')
  end
end
