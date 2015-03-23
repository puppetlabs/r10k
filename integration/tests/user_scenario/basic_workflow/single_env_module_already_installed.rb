require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-117 - C63601 - Single Environment Specify Module that is Already Installed' 

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

forge_module_path = File.join(environment_path, 'production', 'modules')

#Verification
motd_path = '/etc/motd'
motd_template_path = File.join(forge_module_path, 'motd', 'templates', 'motd.erb')
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

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
step 'Add motd module from the forge using the PMT'
on(master, puppet('module', 'install', 'puppetlabs-motd', '--modulepath', forge_module_path)) 

step 'Remove "/etc/motd" File'
on(agents, "rm -rf #{motd_path}")

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k with modules'
on(master, 'r10k deploy environment -p -v')

step 'Update MOTD Template'
create_remote_file(master, motd_template_path, motd_contents)
on(master, "chmod 644 #{motd_template_path}")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Contents of MOTD Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid')
  end
end
