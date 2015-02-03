require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-63 - C62511 - Attempt to Deploy Environment Containing Invalid Character in Name'

#Note: this is not much of a negative test because it actually works.
#Waiting on CODEMGMT-65 so that this actually fails.

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
invalid_env_name = 'should-not-contain-dashes'

#Verification
error_message_regex = /WARN\] Environment "#{invalid_env_name}" contained non-word characters/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step "Create \"#{invalid_env_name}\" Branch from \"production\""
git_on(master, 'checkout production', git_environments_path)
git_on(master, "checkout -b #{invalid_env_name}", git_environments_path)

step "Push Changes to \"#{invalid_env_name}\" Environment"
git_push(master, invalid_env_name, git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v') do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
