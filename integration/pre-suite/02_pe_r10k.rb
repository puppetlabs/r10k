require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-21 - C59119 - Install and Configure r10k for Puppet Enterprise'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_path = File.join(env_path, 'production')

git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")

step 'Get PE Version'
pe_major = on(master, 'facter -p pe_major_version').stdout.rstrip
pe_minor = on(master, 'facter -p pe_minor_version').stdout.rstrip
pe_version = "#{pe_major}.#{pe_minor}".to_f

if pe_version < 3.7
  fail_test('This pre-suite requires PE 3.7 or above!')
end

#In-line files
r10k_conf = <<-CONF
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Setup
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
