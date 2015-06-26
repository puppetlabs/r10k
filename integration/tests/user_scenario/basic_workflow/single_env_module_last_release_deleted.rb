require 'git_utils'
require 'r10k_utils'
test_name 'CODEMGMT-127 - C64120 - Single Environment with Forge Module where Latest Release has been Deleted'

#This test uses the spotty module at https://forge-aio01-petest.puppetlabs.com//puppetlabs/spotty, which has valid 0.1.0 and 0.3.0 versions, and deleted 0.2.0 and 0.4.0 versions.

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_modules_path = File.join(env_path, 'production', 'modules')
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
module_contents = 'Version 3'
module_contents_regex = /\A#{module_contents}\n\z/

module_contents_path = File.join(prod_env_modules_path, 'spotty', 'manifests', 'init.pp')
module_version_filepath = File.join(prod_env_modules_path, 'spotty', 'metadata.json')
module_version_3_regex = /"0.3.0"/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/spotty"
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
step 'Deploy "production" Environment via r10k with modules'
on(master, "#{r10k_fqp} deploy environment -p -v")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Contents'
  on(master, "cat #{module_contents_path}") do |result|
    assert_match(module_contents, result.stdout, 'File Content is Invalid')
  end

  step 'Verify Version'
  on(master, "grep version #{module_version_filepath}") do |result|
    assert_match(module_version_3_regex, result.stdout, 'File Content is Invalid')
  end
end
