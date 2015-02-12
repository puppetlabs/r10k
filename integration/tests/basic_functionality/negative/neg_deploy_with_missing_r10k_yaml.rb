require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-84 - C59118 Attempt to Deploy with Missing r10k Configuration File'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')

r10k_config_path = '/etc/r10k.yaml'
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
sources:
  broken:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Verification
error_message_regex = /Error while running.*R10K\:\:Deployment.*No configuration file/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Remove the "r10k" Config'
on(master, "rm -f #{r10k_config_path}")

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
