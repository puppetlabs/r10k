require 'git_utils'
require 'r10k_utils'
test_name 'CODEMGMT-86 - C63185 - Attempt to Deploy Environment with Invalid Puppetfile'

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#In-line files
puppet_file = <<-PUPPETFILE
- modulo 'puppetlabs/motd",,
PUPPETFILE

#Verification
error_message_regex = /ERROR\].*syntax error/m

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update Puppetfile.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v -p', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
