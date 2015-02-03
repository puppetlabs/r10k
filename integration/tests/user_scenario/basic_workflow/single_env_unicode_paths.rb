require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-62 - C59260 - Single Environment with Unicode File Paths'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
prod_env_modules_path = File.join(environment_path, 'production', 'modules')

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'

unicode_module_path = File.join(local_files_root_path, 'modules', 'unicode')
prod_env_unicode_module_file_path = File.join(prod_env_modules_path, 'unicode', 'files', "\uAD62\uCC63\uC0C3\uBEE7\uBE23\uB7E9\uC715\uCEFE\uBF90\uAE69")

#Verification
unicode_file_contents_regex = /\AHa ha ha! I am in Korean!\n\z/

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include unicode')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "unicode" Module to "production" Environment Git Repo'
scp_to(master, unicode_module_path, File.join(git_environments_path, 'modules'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add modules.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v')

#Note: Usually a full Puppet Run would be performed for verification.
#Since Puppet has problems with Unicode, this test will verify the file
#directly in the r10k environment.

step 'Verify Unicode File'
on(master, "cat #{prod_env_unicode_module_file_path}") do |result|
  assert_match(unicode_file_contents_regex, result.stdout, 'File content is invalid!')
end
