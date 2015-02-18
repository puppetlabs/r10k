require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-84 - C59271 - Attempt to Deploy with Invalid r10k Config'
confine :except, :platform => 'solaris-10'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')

r10k_config_path = '/etc/r10k.yaml'
r10k_config_bak_path = "#{r10k_config_path}.bak"

#Verification
error_message_regex = /ERROR.*can\'t\ convert\ nil\ into\ String/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "cp #{r10k_config_bak_path} #{r10k_config_path}")
end

#Setup
step 'Backup a Valid "r10k" Config'
on(master, "cp #{r10k_config_path} #{r10k_config_bak_path}")

step 'Invalidate the Original "r10k" Config'
on(master, "sed -i 's/dir\:/basedir\:/' #{r10k_config_path}")

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
