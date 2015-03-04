require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-92 - C59238 - Single Git Source with Git Sub-module'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip

git_repo_module_parent_path = '/git_repos'
git_repo_module_name = 'helloworld'
git_repo_module_path = File.join(git_repo_module_parent_path, "#{git_repo_module_name}.git")
git_clone_module_path = '/root/helloworld_module'
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  'Remove "helloworld" Git Repo'
  on(master, "rm -rf #{git_repo_module_path}")

  'Remove "helloworld" Git Clone'
  on(master, "rm -rf #{git_clone_module_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Create Git Repo for "helloworld" Module'
git_init_bare_repo_and_clone(master, git_repo_module_parent_path, git_repo_module_name, git_clone_module_path)

step 'Copy "helloworld" Module to Git Repo'
scp_to(master, helloworld_module_path, File.join(git_clone_module_path, 'helloworld'))
git_add_commit_push(master, 'master', 'Add module.', git_clone_module_path)

step 'Add "helloworld" Module Git Repo as Submodule'
on(master, "cd #{git_environments_path};git submodule add file://#{git_repo_module_path} dist")

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v')

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 1) do |result|
    expect_failure('Expected to fail due to RK-30') do
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
    end
  end
end
