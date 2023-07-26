require 'git_utils'
require 'r10k_utils'
test_name 'CODEMGMT-127 - C64288 - Attempt to Deploy Environment Specify Deleted Forge Module'

#This test uses the regret module deleted from the acceptance forge (history at https://github.com/justinstoller/puppetlabs-regret/commits/master), with versions 0.1.0 - 0.4.0 deleted, effectively deleting the module.

#Init
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

#Verification
error_notification_regex = /(The module puppetlabs-regret does not appear to have any published releases)|(module puppetlabs-regret does not exist on)/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/regret"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Tests
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Add module.', git_environments_path)

#Tests
step "Deploy production environment via r10k with specified module deleted"
on(master, "#{r10k_fqp} deploy environment -p -v --trace", :acceptable_exit_codes => 1) do |result|
  assert_match(error_notification_regex, result.stderr, 'Unexpected error was detected!')
end
