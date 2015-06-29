require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-111 - C63600 - Single Environment Switch Between Forge and Git for Puppetfile Module'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_modules_path = File.join(env_path, 'production', 'modules')
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
motd_path = '/etc/motd'
motd_template_path = File.join(prod_env_modules_path, 'motd', 'templates', 'motd.erb')
motd_template_contents_forge = 'Hello!'
motd_contents_git = 'Bonjour!'
motd_contents_forge_regex = /\A#{motd_template_contents_forge}\n\z/
motd_contents_git_regex = /\A#{motd_contents_git}\z/

#File
puppet_file_forge = <<-PUPPETFILE
mod "puppetlabs/motd", '1.1.1'
PUPPETFILE

puppet_file_git = <<-PUPPETFILE
mod "puppetlabs/motd",
  :git => 'https://github.com/puppetlabs/puppetlabs-motd',
  :tag => '1.2.0'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Manifest
manifest_forge = <<-MANIFEST
  include motd
MANIFEST

manifest_git = <<-MANIFEST
  class { 'motd':
    content => '#{motd_contents_git}',
  }
MANIFEST

site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp_forge = create_site_pp(master_certname, manifest_forge)
site_pp_git = create_site_pp(master_certname, manifest_git)

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")
end

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp_forge)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file_forge)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add modules.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p")

step 'Update MOTD Template'
create_remote_file(master, motd_template_path, motd_template_contents_forge)
on(master, "chmod 644 #{motd_template_path}")

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify MOTD Contents for Forge Version of Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_forge_regex, result.stdout, 'File content is invalid!')
  end
end

step 'Update "Puppetfile" to use Git for MOTD Module'
create_remote_file(master, puppet_file_path, puppet_file_git)

step 'Update "site.pp" in the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp_git)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and Puppetfile.', git_environments_path)

step 'Deploy "production" Environment Again via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p")

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify MOTD Contents for Git Version of Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_git_regex, result.stdout, 'File content is invalid!')
  end
end
