require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-20 - C59120 - Install and Configure Git for r10k'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
prod_env_path = File.join(env_path, 'production')

git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
git_control_remote_head_path = File.join(git_control_remote, 'HEAD')
git_environments_path = File.join('/root', git_repo_name)

step 'Get PE Version'
pe_major = on(master, 'facter -p pe_major_version').stdout.rstrip
pe_minor = on(master, 'facter -p pe_minor_version').stdout.rstrip
pe_version = "#{pe_major}.#{pe_minor}".to_f

if pe_version < 3.7
  fail_test('This pre-suite requires PE 3.7 or above!')
end

#In-line files
git_manifest = <<-MANIFEST
class { 'git': }
->
git::config { 'user.name':
  value => 'Tester',
}
->
git::config { 'user.email':
  value => 'tester@puppetlabs.com',
}
->
file { '#{git_repo_path}':
  ensure => directory
}
MANIFEST

#Setup
step 'Stub Forge on Master'
stub_forge_on(master)

step 'Install "git" Module'
on(master, puppet('module install puppetlabs-git --modulepath /opt/puppet/share/puppet/modules'))

step 'Install and Configure Git'
on(master, puppet('apply'), :stdin => git_manifest, :acceptable_exit_codes => [0,2]) do |result|
  assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
end

step 'Create "production" Environment on Git'
init_r10k_source_from_prod(master, git_repo_path, git_repo_name, git_environments_path, 'production')

step 'Change Default Branch to "production" on Git Control Remote'
create_remote_file(master, git_control_remote_head_path, "ref: refs/heads/production\n")
on(master, "chmod 644 #{git_control_remote_head_path}")
