require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-101 - C59231 - Attempt to Deploy Environment from Git Source with Branches Containing Unicode'

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

unicode_env = "\uAD62\uCC63\uC0C3\uBEE7\uBE23\uB7E9\uC715\uCEFE\uBF90\uAE69"

#Verification
error_message_regex = /ERROR\].*Blah/m

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step "Create \"#{unicode_env}\" Branch from \"production\""
git_on(master, 'checkout production', git_environments_path)
git_on(master, "checkout -b #{unicode_env}".force_encoding('BINARY'), git_environments_path)

step "Push Changes to \"#{unicode_env}\" Environment"
git_push(master, unicode_env, git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v -t', :acceptable_exit_codes => 0) do |result|
  binding.pry
  expect_failure('Expected to fail due to RK-29') do
    assert_match(error_message_regex, result.stderr, 'Expected message not found!')
  end
end
