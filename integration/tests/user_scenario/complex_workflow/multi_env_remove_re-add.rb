require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-48 - C59263 - Multiple Environments with Adding, Removing and Re-adding Same Branch Name'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')
r10k_fqp = get_r10k_fqp(master)

initial_env_names = ['production', 'stage']

#Verification
notify_message_regex = /I am in the production environment/
stage_env_error_message_regex = /Error:.*Could not find environment 'stage'/

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
initial_env_names.each do |env|
  if env == 'production'
    step "Checkout \"#{env}\" Branch"
    git_on(master, "checkout #{env}", git_environments_path)

    step "Copy \"helloworld\" Module to \"#{env}\" Environment Git Repo"
    scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

    step "Inject New \"site.pp\" to the \"#{env}\" Environment"
    inject_site_pp(master, site_pp_path, site_pp)

    step "Push Changes to \"#{env}\" Environment"
    git_add_commit_push(master, env, 'Update site.pp and add module.', git_environments_path)
  else
    step "Create \"#{env}\" Branch from \"production\""
    git_on(master, 'checkout production', git_environments_path)
    git_on(master, "checkout -b #{env}", git_environments_path)

    step "Push Changes to \"#{env}\" Environment"
    git_push(master, env, git_environments_path)
  end
end

#Tests
step 'Deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

#Initial Verification
initial_env_names.each do |env|
  agents.each do |agent|
    step "Run Puppet Agent Against \"#{env}\" Environment"
    on(agent, puppet('agent', '--test', "--environment #{env}"), :acceptable_exit_codes => 2) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(/I am in the #{env} environment/, result.stdout, 'Expected message not found!')
    end
  end
end

#Remove "stage" Environment
step 'Delete the "stage" Environment'
git_on(master, 'checkout production', git_environments_path)
git_on(master, 'branch -D stage', git_environments_path)
git_on(master, 'push origin --delete stage', git_environments_path)

step 'Re-deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

#Second Pass Verification
agents.each do |agent|
  step 'Run Puppet Agent Against "production" Environment'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end

  step 'Attempt to Run Puppet Agent Against "stage" Environment'
  on(agent, puppet('agent', '--test', '--environment stage'), :acceptable_exit_codes => 1) do |result|
    assert_match(stage_env_error_message_regex, result.stderr, 'Expected error was not detected!')
  end
end

#Create the "stage" Environment Again
step 'Create "stage" Branch from "production"'
git_on(master, 'checkout production', git_environments_path)
git_on(master, 'checkout -b stage', git_environments_path)

step 'Push Changes to "stage" Environment'
git_push(master, 'stage', git_environments_path)

step 'Re-deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

#Final Verification
initial_env_names.each do |env|
  agents.each do |agent|
    step "Run Puppet Agent Against \"#{env}\" Environment"
    on(agent, puppet('agent', '--test', "--environment #{env}"), :acceptable_exit_codes => 2) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(/I am in the #{env} environment/, result.stdout, 'Expected message not found!')
    end
  end
end
