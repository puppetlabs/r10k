require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-90 - C62419 - Deploy Environment without Module'
confine :except, :platform=> 'solaris-10'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, "include helloworld")

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -p -v')

step 'Update "helloworld module"'
on(master, "sed -i 's/environment\"/land\"/' ~/environments/site/helloworld/manifests/init.pp") 
#errs at ')'
#on(master, "ruby -pe 'sub!(/am in/, "rule")' < ~/environments/site/helloworld/manifests/init.pp")

#Tests
step 'Deploy "production" Environment via r10k without module update'
on(master, 'r10k deploy environment production -v')

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
