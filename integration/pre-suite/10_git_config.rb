require 'erb'
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

local_files_root_path = ENV['FILES'] || 'files'
git_manifest_template_path = File.join(local_files_root_path, 'pre-suite', 'git_config.pp.erb')
git_manifest = ERB.new(File.read(git_manifest_template_path)).result(binding)

step 'Get PE Version'
pe_version = get_puppet_version(master)
fail_test('This pre-suite requires PE 3.7 or above!') if pe_version < 3.7

#Setup
step 'Read module path'
on(master, puppet('config print basemodulepath')) do |result|
  (result.stdout.include? ':') ? separator = ':' : separator = ';'
  @module_path = result.stdout.split(separator).first
end

step 'Install "git" Module'
on(master, puppet("module install  puppetlabs-git --modulepath #{@module_path}"))

step 'Install and Configure Git'
on(master, puppet('apply'), :stdin => git_manifest, :acceptable_exit_codes => [0,2]) do |result|
  assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
end
on(master, 'git config --system --add safe.directory "*"')

step 'Create "production" Environment on Git'
init_r10k_source_from_prod(master, git_repo_path, git_repo_name, git_environments_path, 'production')

step 'Change Default Branch to "production" on Git Control Remote'
create_remote_file(master, git_control_remote_head_path, "ref: refs/heads/production\n")
on(master, "chmod 644 #{git_control_remote_head_path}")
