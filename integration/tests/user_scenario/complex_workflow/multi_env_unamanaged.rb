require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-155 - C62421 - Multiple Environments with Existing Unmanaged Environments'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_prod_env_regex = /I am in the production environment/
notify_message_test_env_regex = /I am in the test environment/
removal_message_test_env_regex = /Removing unmanaged path.*test/
missing_message_regex = /Environment 'test' not found on server/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_prod_env_regex, result.stdout, 'Expected message not found!')
  end
end

step 'Create Unmanaged "test" Environment'
on(master, "cp -r #{environment_path}/production #{environment_path}/test")

agents.each do |agent|
  step 'Run Puppet Agent Against "test" Environment'
  on(agent, puppet('agent', '--test', '--environment test'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_test_env_regex, result.stdout, 'Expected message not found!')
  end
end

step 'Re-deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v") do |result|
  assert_match(removal_message_test_env_regex, result.output, 'Unexpected error was detected!')
end

agents.each do |agent|
  step 'Run Puppet Agent Against "test" Environment'
  on(agent, puppet('agent', '--test', '--environment test'), :acceptable_exit_codes => 2) do |result|
    assert_match(missing_message_regex, result.stdout, 'Expected message not found!')
  end
end
