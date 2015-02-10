require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-73 - C63184 - Single Enviornment Purge Unmanaged Modules'

skip_test('Skipping test because of CODEMGMT-78')

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

error_message_regex = /Blah/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/apache"
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
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Manually Install the "motd" Module from the Forge'
on(master, puppet('module install puppetlabs-motd'))

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy Environments via r10k'
on(master, 'r10k deploy environment -v -p')

step 'Plug-in Sync Agents'
on(agents, puppet("plugin download --server #{master}"))

agents.each do |agent|
  step 'Run Puppet Agent Against "production" Environment'
  on(agent, puppet('agent', '--test'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Verify MOTD Contents"
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end
end

step 'Use r10k to Purge Unmanaged Modules'
on(master, 'r10k puppetfile purge -v')

#Agent will fail because r10k will purge the "motd" module
agents.each do |agent|
  step 'Attempt to Run Puppet Agent'
  on(agent, puppet('agent', '--test'), :acceptable_exit_codes => 1) do |result|
    assert_match(error_message_regex, result.stderr, 'Expected error was not detected!')
  end
end
