require 'git_utils'
require 'master_manipulator'
test_name 'Install and Configure r10k for Puppet Enterprise'

#Init
git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')
git_environments_path = '/root/environments'

local_files_root_path = ENV['FILES'] || 'files'
prod_env_config_path = 'pre-suite/prod_env.config'
prod_env_config = File.read(File.join(local_files_root_path, prod_env_config_path))

puppet_confdir = on(master, puppet('config', 'print', 'confdir')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_path = File.join(env_path, 'production')

step 'Get PE Version'
pe_major = on(master, 'facter -p pe_major_version').stdout.rstrip
pe_minor = on(master, 'facter -p pe_minor_version').stdout.rstrip
pe_version = "#{pe_major}.#{pe_minor}".to_f

if pe_version < 3.7
  fail_test('This pre-suite requires PE 3.7 or above!')
end

#In-line files
git_manifest = <<-MANIFEST
class { 'git': }
->
git::config { 'user.name':
  value => 'Tester',
}
->
git::config { 'user.email':
  value => 'tester@puppetlabs.com',
}
->
file { '#{git_repo_path}':
  ensure => directory
}
->
vcsrepo { '#{git_control_remote}':
  ensure   => bare,
  provider => git
}
->
vcsrepo { '#{git_environments_path}':
  ensure   => present,
  provider => git,
  source   => '#{git_control_remote}'
}
MANIFEST

r10k_conf = <<-CONF
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Setup
step 'Install "vcsrepo" Module'
on(master, puppet('module install puppetlabs-vcsrepo --modulepath /opt/puppet/share/puppet/modules'))

step 'Install "git" Module'
on(master, puppet('module install puppetlabs-git --modulepath /opt/puppet/share/puppet/modules'))

step 'Create Git Repo and Clone'
on(master, puppet('apply'), :stdin => git_manifest, :acceptable_exit_codes => [0,2]) do |result|
  assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
end

step 'Create "production" Environment on Git'
#Copy current contents of production environment to the git version
on(master, "cp -r #{prod_env_path}/* #{git_environments_path}")

#Create hidden files in the "site" and "modules" folders so that git copies the directories.
on(master, "mkdir -p #{git_environments_path}/modules #{git_environments_path}/site")
on(master, "touch #{git_environments_path}/modules/.keep;touch #{git_environments_path}/site/.keep")

#Add environment config that specifies module lookup path for production.
create_remote_file(master, "#{git_environments_path}/environment.conf", prod_env_config)
git_on(master, "add #{git_environments_path}/*", git_environments_path)
git_on(master, "commit -m \"Add production environment.\"", git_environments_path)
git_on(master, "branch -m production", git_environments_path)
git_on(master, "push -u origin production", git_environments_path)

step 'Remove Current Puppet "production" Environment'
on(master, "rm -rf #{prod_env_path}")

step 'Install and Configure r10k'
on(master, 'gem install r10k')
create_remote_file(master, '/etc/r10k.yaml', r10k_conf)

step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v')

step 'Disable Environment Caching on Master'
on(master, puppet('config set environment_timeout 0 --section main'))

#This should be temporary until we get a better solution.
step 'Disable Node Classifier'
on(master, puppet('config', 'set node_terminus plain', '--section master'))

step 'Restart the Puppet Server Service'
restart_puppet_server(master)

step 'Run Puppet Agent on All Nodes'
on(agents, puppet('agent -t'))
