require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-158 - C92362 - Install a PE-only module from forge'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip

git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'

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
site_pp = create_site_pp(master_certname, '  include peonly')

# Verification
notify_message_regex = /I am in the production environment, this is a PE only module/

#Teardown
teardown do
  step 'remove license file'
  on(master, 'rm -f /etc/puppetlabs/license.key')

  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'cleanup r10k'
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Stub the forge'
stub_forge_on(master)

step 'Backup a Valid "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Download license file from artifactory'
curl_on(master, 'https://artifactory.delivery.puppetlabs.net/artifactory/generic/r10k_test_license.key -o /etc/puppetlabs/license.key')

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Copy Puppetfile to "production" Environment Git Repo'
create_remote_file(master, "#{git_environments_path}/Puppetfile", 'mod "ztr-peonly"')

step 'Push Changes'
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -p")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
