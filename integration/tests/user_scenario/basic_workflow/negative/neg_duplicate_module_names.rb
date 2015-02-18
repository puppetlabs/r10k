require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-63 - C59258 - Attempt to Deploy Environment with Duplicate Module Names'

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
error_message_regex = /ERROR\]/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
mod "jeffmccune/motd"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Add modules.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v -p', :acceptable_exit_codes => 0) do |result|
  expect_failure('Expected to fail due to CODEMGMT-71') do
    assert_match(error_message_regex, result.stderr, 'Expected message not found!')
  end
end
