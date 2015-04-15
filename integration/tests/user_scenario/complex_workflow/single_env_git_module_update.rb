require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-155 - C64588 - Single Environment with Git Module Using a Branch Reference where Updates Occur After Initial Deploy'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip

git_repo_parent_path = '/git_repos'
git_repo_module_name = 'helloworld_module'
git_remote_module_path = File.join(git_repo_parent_path, "#{git_repo_module_name}.git")
git_module_clone_path = '/root/helloworld'

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Verification
notify_original_message_regex = /I am in the production environment/
notify_updated_message = 'A totally different message'
notify_updated_message_regex = /#{notify_updated_message}/

#File
puppet_file = <<-PUPPETFILE
mod 'test/helloworld',
  :git => '#{git_remote_module_path}',
  :ref => 'master'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

updated_helloworld_manifest = <<-MANIFEST
class helloworld {
  notify { "Hello world!": message => "#{notify_updated_message}"}
}
MANIFEST

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Teardown
teardown do
  step 'Remove Git Repo and Clone for Module'
  on(master, "rm -rf #{git_remote_module_path} #{git_module_clone_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Create Bare Git Repo and Clone'
on(master, "mkdir -p #{git_remote_module_path} #{git_module_clone_path}")
git_init_bare_repo_and_clone(master, git_repo_parent_path, git_repo_module_name, git_module_clone_path)

step 'Copy "helloworld" Module to Git Repo'
scp_to(master, "#{helloworld_module_path}/manifests", git_module_clone_path)

step 'Push Changes for Module Git Repo to Remote'
git_add_commit_push(master, 'master', 'Add module.', git_module_clone_path)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes to Environments Git Repo Remote'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v -p')

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_original_message_regex, result.stdout, 'Expected message not found!')
  end
end

step 'Update "helloworld" Module and Push Changes'
create_remote_file(master, "#{git_module_clone_path}/manifests/init.pp", updated_helloworld_manifest)
on(master, "chmod -R 644 #{git_module_clone_path}")
git_add_commit_push(master, 'master', 'Update module.', git_module_clone_path)

step 'Deploy "production" Environment Again via r10k'
on(master, 'r10k deploy environment -v -p')

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_updated_message_regex, result.stdout, 'Expected message not found!')
  end
end
