require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-90 - C63462 - Specify Invalid Command line Environment Flag'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
error_message_regex = /environment: illegal option/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -x', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
