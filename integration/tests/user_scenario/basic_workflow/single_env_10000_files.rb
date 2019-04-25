require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-62 - C59239 - Single Environment with 10,000 Files'

if fact_on(master, 'osfamily') == 'RedHat' and fact_on(master, "operatingsystemmajrelease").to_i < 6
  skip_test('This version of EL is not supported by this test case!')
end

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
prod_env_path = File.join(environment_path, 'production')
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

test_files = 'test_files'
test_files_path = File.join(git_environments_path, test_files)

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_regex = /I am in the production environment/

checksum_file_name = 'files.md5'
prod_env_test_files_path = File.join(prod_env_path, test_files)
prod_env_checksum_file_path = File.join(prod_env_test_files_path, checksum_file_name)

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Create 10,000 Files'
create_remote_file(master, File.join(git_environments_path, '.gitattributes'), '*.file binary')
on(master, "mkdir -p #{test_files_path}")
# create 10000 1k files with random text
on(master, "for n in {1..10000}; do dd if=/dev/urandom of=#{test_files_path}/test$( printf %03d \"$n\" ).file bs=1024 count=1; done")

step 'Create MD5 Checksum of Files'
on(master, "cd #{test_files_path};md5sum *.file > #{checksum_file_name}")

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

step 'Verify Files in "production" Environment'
on(master, "cd #{prod_env_test_files_path};md5sum -c #{prod_env_checksum_file_path}")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
