require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-40 - C59222 - Single Environment with Custom, Forge and Git Modules'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')
r10k_fqp = get_r10k_fqp(master)

#Verification
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

ini_file_path = '/tmp/foo.ini'
ini_file_section = 'foo'
ini_file_setting = 'foosetting'
ini_file_value = 'FOO!'
ini_file_contents_regex = /\[#{ini_file_section}\].*#{ini_file_setting}\s=\s#{ini_file_value}/m

notify_message_regex = /I am in the production environment/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
mod 'puppetlabs/inifile',
  :git => 'https://github.com/puppetlabs/puppetlabs-inifile'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Manifest
manifest = <<-MANIFEST
  class { 'helloworld': }
  class { 'motd':
    content => '#{motd_contents}',
  }
  ini_setting { "sample setting":
    ensure  => present,
    path    => '#{ini_file_path}',
    section => '#{ini_file_section}',
    setting => '#{ini_file_setting}',
    value   => '#{ini_file_value}',
  }
MANIFEST

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, manifest)

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")

  step 'Remove Temp INI File'
  on(agents, "rm -rf #{ini_file_path}")
end

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add modules.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end

  step "Verify MOTD Contents"
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step "Verify INI File Contents"
  on(agent, "cat #{ini_file_path}") do |result|
    assert_match(ini_file_contents_regex, result.stdout, 'File content is invalid!')
  end
end
