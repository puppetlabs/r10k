require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-90 - C62419 - Deploy Environment without Module Update'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
prod_env_path = File.join(environment_path, 'production')

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
motd_module_init_pp_path = File.join(prod_env_path, 'modules/motd/manifests/init.pp')

#Verification
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

error_message_regex = /Error:/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Manifest
manifest = <<-MANIFEST
  class { 'motd':
    content => '#{motd_contents}',
}
MANIFEST

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, manifest)

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")
end

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

step 'Deploy "production" Environment via r10k with modules'
on(master, 'r10k deploy environment -p -v')

step 'Corrupt MOTD Manifest'
create_remote_file(master, motd_module_init_pp_path, 'Broken')

#Tests
step 'Deploy "production" Environment via r10k without module update'
on(master, 'r10k deploy environment -v')

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 1) do |result|
    assert_match(error_message_regex, result.stderr)
  end
end
