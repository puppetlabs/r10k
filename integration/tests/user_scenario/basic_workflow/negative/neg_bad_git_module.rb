require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-42 - C59229 - Attempt to Deploy Environment with Non-existent Git Module'

if ENV['GIT_PROVIDER'] == 'shellgit'
  skip_test('Skipping test because of known failure RK-80.')
end

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

#File
puppet_file = <<-PUPPETFILE
mod 'broken', :git => 'git://github.com/puppetlabs/puppetlabs-broken'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Verification
error_message_regex = /ERROR.*uses the SSH protocol but no private key was given/

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
on(master, "#{r10k_fqp} deploy environment -v -p", :acceptable_exit_codes => 1) do |result|
  assert_no_match(error_message_regex, result.stderr, 'Expected message not found!')
end
