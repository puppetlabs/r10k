require 'git_utils'
require 'r10k_utils'
test_name 'CODEMGMT-127 - C64121 - Attempt to Deploy Environment with Forge Module Specified at Deleted Release' 

#This test uses the spotty module at https://forge-aio01-petest.puppetlabs.com//puppetlabs/spotty, with valid released 0.1.0 and 0.3.0 versions, and deleted 0.2.0 and 0.4.0 versions.

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

#Verification
if get_puppet_version(master) < 4.0
  error_notification_regex = /No releases matching '0.2.0'/
else
  error_notification_regex = /error.* -> The module release puppetlabs-spotty-0.2.0 does not exist on/i
end

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/spotty", '0.2.0'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

#Tests
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Add module.', git_environments_path)

#Tests
step "Deploy production environment via r10k with module specified at deleted version"
on(master, "#{r10k_fqp} deploy environment -p -v", :acceptable_exit_codes => 1) do |result|
  assert_match(error_notification_regex, result.stderr, 'Unexpected error was detected!')
end
