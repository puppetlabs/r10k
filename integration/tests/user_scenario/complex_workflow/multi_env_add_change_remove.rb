require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-48 - C59262 - Multiple Environments with Additions, Changes and Removal of Branches'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

initial_env_names = ['production', 'stage', 'test']

#Verification for "production" Environment
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/
prod_env_notify_message_regex = /I am in the production environment/

#Verification for "stage" Environment
stage_env_notify_message = 'This is a different message'
stage_env_notify_message_regex = /#{stage_env_notify_message}/

#Verification for "test" Environment
test_env_error_message_regex = /Error:.*Could not find environment 'test'/

#Verification for "temp" Environment
test_env_notify_message_regex = /I am in the temp environment/

#Manifest
prod_env_motd_manifest = <<-MANIFEST
  class { 'helloworld': }
  class { 'motd':
    content => '#{motd_contents}',
  }
MANIFEST

stage_env_custom_mod_manifest = <<-MANIFEST
  class helloworld {
    notify { "Hello world!":
      message => "#{stage_env_notify_message}"
    }
  }
MANIFEST

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
original_site_pp = create_site_pp(master_certname, '  include helloworld')
prod_env_motd_site_pp = create_site_pp(master_certname, prod_env_motd_manifest)

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")
end

#Setup
initial_env_names.each do |env|
  if env == 'production'
    step "Checkout \"#{env}\" Branch"
    git_on(master, "checkout #{env}", git_environments_path)

    step "Copy \"helloworld\" Module to \"#{env}\" Environment Git Repo"
    scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

    step "Inject New \"site.pp\" to the \"#{env}\" Environment"
    inject_site_pp(master, site_pp_path, original_site_pp)

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
on(master, 'r10k deploy environment -v')

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

#Add, Change, Remove Environments
step 'Create "temp" Branch from "production"'
git_on(master, 'checkout production', git_environments_path)
git_on(master, 'checkout -b temp', git_environments_path)
git_push(master, 'temp', git_environments_path)

step 'Add "puppetlabs-motd" Module to the "production" Environment'
git_on(master, 'checkout production', git_environments_path)
inject_site_pp(master, site_pp_path, prod_env_motd_site_pp)
create_remote_file(master, puppet_file_path, puppet_file)
git_add_commit_push(master, 'production', 'Add motd module.', git_environments_path)

step 'Update Custom Module in the "stage" Environment'
hw_init_pp_path = File.join(git_environments_path, 'site', 'helloworld', 'manifests', 'init.pp')
git_on(master, 'checkout stage', git_environments_path)
create_remote_file(master, hw_init_pp_path, stage_env_custom_mod_manifest)
git_add_commit_push(master, 'stage', 'Update custom module.', git_environments_path)

step 'Delete the "test" Environment'
git_on(master, 'branch -D test', git_environments_path)
git_on(master, 'push origin --delete test', git_environments_path)

step 'Re-deploy Environments via r10k'
on(master, 'r10k deploy environment -v -p')

#Second Pass Verification
agents.each do |agent|
  step 'Run Puppet Agent Against "production" Environment'
  on(agent, puppet('agent', '--test'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(prod_env_notify_message_regex, result.stdout, 'Expected message not found!')
  end

  step 'Run Puppet Agent Against "temp" Environment'
  on(agent, puppet('agent', '--test', '--environment temp'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(test_env_notify_message_regex, result.stdout, 'Expected message not found!')
  end

  step "Verify MOTD Contents"
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step 'Run Puppet Agent Against "stage" Environment'
  on(agent, puppet('agent', '--test', '--environment stage'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(stage_env_notify_message_regex, result.stdout, 'Expected message not found!')
  end

  step 'Attempt to Run Puppet Agent Against "test" Environment'
  on(agent, puppet('agent', '--test', '--environment test'), :acceptable_exit_codes => 1) do |result|
    assert_match(test_env_error_message_regex, result.stderr, 'Expected error was not detected!')
  end
end
