require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-78 - Puppetfile Purge --puppetfile & --moduledir flag usage'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environments_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.strip
moduledir = File.join(environments_path, 'production', 'modules')
puppetfile_path = File.join(environments_path, 'production', 'Puppetfile')
git_remote_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_remote_environments_path)
r10k_fqp = get_r10k_fqp(master)

#Verification
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

#File
puppetfile = <<-PUPPETFILE
mod "puppetlabs/xinetd"
PUPPETFILE

remote_puppetfile_path = File.join(git_remote_environments_path, 'Puppetfile')

#Manifest
manifest = <<-MANIFEST
  class { 'motd':
    content => '#{motd_contents}',
  }
MANIFEST

remote_site_pp_path = File.join(git_remote_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, manifest)

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_remote_environments_path)

  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")
end

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_remote_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, remote_puppetfile_path, puppetfile)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, remote_site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_remote_environments_path)

step 'Deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment --modules --verbose debug --trace")

step 'Manually Install the "motd" Module from the Forge'
on(master, puppet("module install puppetlabs-motd --modulepath #{moduledir}"))

#Tests
agents.each do |agent|
  step 'Run Puppet Agent Against "production" Environment'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Verify MOTD Contents"
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end
end

step 'Use r10k to Purge Unmanaged Modules'
on(master, "#{r10k_fqp} puppetfile purge --puppetfile #{puppetfile_path} --moduledir #{moduledir} --verbose debug --trace")

#Agent will fail because r10k will purge the "motd" module
agents.each do |agent|
  step 'Attempt to Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 1) do |result|
    assert_match(/Could not find declared class motd/, result.stderr, 'Module was not purged')
  end
end
