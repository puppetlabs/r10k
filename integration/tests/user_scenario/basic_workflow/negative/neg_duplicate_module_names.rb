require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-63 - C59258 - Attempt to Deploy Environment with Duplicate Module Names'

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

#Verification
deploy_str = %r[Deploying module /etc/puppetlabs/code/environments/production/modules/motd]

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
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Add modules.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p", :acceptable_exit_codes => [0, 1]) do |result|
  assert_equal(1, result.exit_code, "Expected command to indicate error with exit code")
end
