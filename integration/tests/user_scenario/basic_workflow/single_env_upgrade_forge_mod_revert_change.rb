require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-117 - C63602- Single Environment Upgrade Forge Module then Revert Change'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_modules_path = File.join(env_path, 'production', 'modules')

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)

#Verification
motd_path = '/etc/motd'
motd_template_path = File.join(prod_env_modules_path, 'motd', 'templates', 'motd.erb')
motd_template_contents = 'Hello!'
motd_contents_regex = /\A#{motd_template_contents}\n\z/

motd_old_version = /"*1.1.1*"/
motd_new_version = /"*1.2.0*"/
motd_version_file_path = File.join(prod_env_modules_path, 'motd', 'metadata.json')

#File
puppet_file_old_motd = <<-PUPPETFILE
mod "puppetlabs/motd", '1.1.1'
PUPPETFILE

puppet_file_new_motd = <<-PUPPETFILE
mod "puppetlabs/motd", '1.2.0'
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')
puppet_file_path_bak = "#{puppet_file_path}.bak"

#Manifest
manifest = <<-MANIFEST
  include motd
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

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file_old_motd)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add modules.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v -p')

step 'Update MOTD Template'
create_remote_file(master, motd_template_path, motd_template_contents)
on(master, "chmod 644 #{motd_template_path}")

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify MOTD Contents for Forge Version of Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step 'Verify Version 1.1.1 of the MOTD Module'
  on(master, "grep version #{motd_version_file_path}") do |result|
    assert_match(motd_old_version, result.stdout, 'File content is invalid!')
  end
end

step 'Backup Old MOTD "Puppetfile" to allow for creation of New MOTD "Puppetfile"'
on(master, "mv #{puppet_file_path} #{puppet_file_path_bak}")

step 'Update "Puppetfile" to use New Module Version 1.2.0'
create_remote_file(master, puppet_file_path, puppet_file_new_motd)

step 'Update "site.pp" in the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and Puppetfile.', git_environments_path)

step 'Deploy "production" Environment Again via r10k'
on(master, 'r10k deploy environment -v -p')

#step 'Update MOTD Template'
#create_remote_file(master, motd_template_path, motd_template_contents)
#on(master, "chmod 644 #{motd_template_path}")

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify MOTD Contents for New Version of Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step 'Verify Version 1.2.0 of the MOTD Module'
  on(master, "grep version #{motd_version_file_path}") do |result|
    assert_match(motd_new_version, result.stdout, 'File content is invalid!')
  end
end

step 'Restore Old MOTD "Puppetfile"'
on(master, "mv #{puppet_file_path_bak} #{puppet_file_path}")

step 'Update "site.pp" in the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add modules.', git_environments_path)

step 'Deploy "production" Environment Again via r10k'
on(master, 'r10k deploy environment -v -p')

step 'Update MOTD Template'
create_remote_file(master, motd_template_path, motd_template_contents)

agents.each do |agent|
  step 'Run Puppet Agent'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify MOTD Contents for Old Version of Module'
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step 'Verify Version 1.1.1 of the MOTD Module'
  on(master, "grep version #{motd_version_file_path}") do |result|
    assert_match(motd_old_version, result.stdout, 'File content is invalid!')
  end
end
