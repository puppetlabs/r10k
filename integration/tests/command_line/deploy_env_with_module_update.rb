require 'pry'
require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-90 - C62418 - Deploy Environment with Module Update'
confine :except, :platform=> 'solaris-10'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Verification
motd_path = '/etc/motd'
motd_contents = 'Yo!'
motd_contents_regex = /\A#{motd_contents}\z/

notify_message_regex = /changed '{md5}d41d8cd98f00b204e9800998ecf8427e' to '{md5}79701ff5201b73240aafbf22b8691454/

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Manifest
manifest = <<-MANIFEST
  class { 'helloworld': }
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
#step 'Checkout "production" Branch'
#git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

step 'Deploy "production" Environment via r10k with modules'
on(master, 'r10k deploy environment -p -v')

step 'Update the Module' 
on(master, "sed -i 's/Hello/Yo/' ~/environments/manifests/site.pp")

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

#Tests
step 'Deploy "production" Environment via r10k with module update'
on(master, 'r10k deploy environment production -p -v')

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
