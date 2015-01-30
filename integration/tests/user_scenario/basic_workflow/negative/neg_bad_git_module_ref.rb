require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-42 - C59230 - Attempt to Deploy Environment with Invalid Git Module Reference'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#File
puppet_file = <<-PUPPETFILE
mod 'broken',
  :git => 'https://github.com/puppetlabs/puppetlabs-motd',
  :ref => 'does_not_exist'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Verification
error_message_regex = /Cannot check out Git ref 'does_not_exist'/

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
git_add_commit_push(master, 'production', 'Update Puppetfile.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v -p', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
