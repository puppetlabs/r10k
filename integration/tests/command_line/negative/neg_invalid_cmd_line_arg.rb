require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-90 - C62420 - Invalid Command Line Argument'

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

#Verification
error_message_regex = /error/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment NONEXISTENTENV -v", :acceptable_exit_codes => [0, 1, 2]) do |result|
  expect_failure('expected to fail due to RK-21') do
    assert_match(/error/, result.stderr.downcase, 'Expected message not found!')
  end
end
