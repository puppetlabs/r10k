require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-63 - C59257 - Attempt to Deploy Multiple Sources with Branch Name Collision'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip

git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
git_environments_path = File.join('/root', git_repo_name)

git_alt_repo_path = '/git_repos_alt'
git_alt_repo_name = 'environments_alt'
git_alt_control_remote = File.join(git_alt_repo_path, "#{git_alt_repo_name}.git")
git_alt_environments_path = File.join('/root', git_alt_repo_name)

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
  alt_control:
    basedir: "#{env_path}"
    remote: "#{git_alt_control_remote}"
CONF

#Verification
error_message_regex = /ERROR\] Environment collision/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Alternate Git Source'
  on(master, "rm -rf #{git_alt_repo_path} #{git_alt_environments_path}")
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Create Alternate Git Repo and Clone'
init_r10k_source_from_prod(master, git_alt_repo_path, git_alt_repo_name, git_alt_environments_path, 'production')

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
