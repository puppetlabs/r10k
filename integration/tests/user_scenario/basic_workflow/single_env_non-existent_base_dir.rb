require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-62 - C62387 - Single Environment Deployed to Non-existent Base Directory Path'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
original_env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
env_path = '/tmp/puppet/temp/environments'
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'

last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  step 'Restore Original "environmentpath" Path'
  on(master, puppet("config set environmentpath \"#{original_env_path}\""))

  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Temporary Environments Path'
  on(master, "rm -rf #{env_path}")

  step 'Restart the Puppet Server Service'
  restart_puppet_server(master)

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Change Puppet "environmentpath"'
on(master, puppet("config set environmentpath \"#{env_path}\""))

step 'Restart the Puppet Server Service'
restart_puppet_server(master)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
