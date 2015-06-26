require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-102 - C63192 - Multiple Environments with Hiera Data'

skip_test('This test is blocked by RK-136')

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

local_files_root_path = ENV['FILES'] || 'files'
hieratest_module_path = File.join(local_files_root_path, 'modules', 'hieratest')

hiera_local_config_path = File.join(local_files_root_path, 'hiera.yaml')
hiera_master_config_path = on(master, puppet('config', 'print', 'hiera_config')).stdout.rstrip
if get_puppet_version(master) < 4.0
  hiera_data_dir = File.join(git_environments_path, 'hiera')
else
  hiera_data_dir = File.join(git_environments_path, 'hieradata')
end

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include hieratest')

env_names = ['production', 'stage', 'test']

#Teardown
teardown do
  step 'Restore Original "hiera.yaml" Config'
  on(master, "mv #{hiera_master_config_path}.bak #{hiera_master_config_path}")

  step 'Restart the Puppet Server Service'
  restart_puppet_server(master)

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Backup Current "hiera.yaml" Config'
on(master, "mv #{hiera_master_config_path} #{hiera_master_config_path}.bak")

step 'Copy New "hiera.yaml" to Puppet Master'
scp_to(master, hiera_local_config_path, hiera_master_config_path)

env_names.each do |env|
  #In-line Files
  hiera_data = <<-HIERA
---
hieratest::hiera_message: "I am in the #{env} environment"
HIERA

  if env == 'production'
    step "Checkout \"#{env}\" Branch"
    git_on(master, "checkout #{env}", git_environments_path)

    step "Copy \"hieratest\" Module to \"#{env}\" Environment Git Repo"
    scp_to(master, hieratest_module_path, File.join(git_environments_path, "site", 'hieratest'))

    step "Update Hiera Data for \"#{env}\" Environment"
    on(master, "mkdir -p #{hiera_data_dir}")
    create_remote_file(master, File.join(hiera_data_dir, "#{env}.yaml"), hiera_data)

    step "Inject New \"site.pp\" to the \"#{env}\" Environment"
    inject_site_pp(master, site_pp_path, site_pp)

    step "Push Changes to \"#{env}\" Environment"
    git_add_commit_push(master, env, 'Update site.pp, add hiera data.', git_environments_path)
  else
    step "Create \"#{env}\" Branch from \"production\""
    git_on(master, 'checkout production', git_environments_path)
    git_on(master, "checkout -b #{env}", git_environments_path)

    step "Update Hiera Data for \"#{env}\" Environment"
    create_remote_file(master, File.join(hiera_data_dir, "#{env}.yaml"), hiera_data)

    step "Push Changes to \"#{env}\" Environment"
    git_add_commit_push(master, env, 'Add hiera data.', git_environments_path)
  end
end

step 'Restart the Puppet Server Service'
restart_puppet_server(master)

#Tests
step 'Deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

env_names.each do |env|
  agents.each do |agent|
    step "Run Puppet Agent Against \"#{env}\" Environment"
    on(agent, puppet('agent', '--test', "--environment #{env}"), :acceptable_exit_codes => 2) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(/I am in the #{env} environment/, result.stdout, 'Expected message not found!')
    end
  end
end
