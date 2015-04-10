require 'git_utils'
require 'r10k_utils'
test_name 'CODEMGMT-86 - C59265 - Attempt to Deploy Environment to Disk with Insufficient Free Space'

if fact_on(master, 'osfamily') == 'RedHat' and fact_on(master, "operatingsystemmajrelease").to_i < 6
  skip_test('This version of EL is not supported by this test case!')
end

#Init
git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

tmpfs_path = '/mnt/tmpfs'

file_bucket_path = '/opt/filebucket'
file_bucket_command_path = File.join(file_bucket_path, 'filebucketapp.py')
pattern_file_path = File.join(file_bucket_path, 'psuedo_random_128k.pat')

test_files_path = File.join(git_environments_path, 'test_files')

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  broken:
    basedir: "#{tmpfs_path}"
    remote: "#{git_control_remote}"
CONF

#Verification
error_message_regex = /ERROR.*No space left on device/m

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Unmount and Destroy TMP File System'
  on(master, "umount #{tmpfs_path}")
  on(master, "rm -rf #{tmpfs_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Create TMP File System and Mount'
on(master, "mkdir -p #{tmpfs_path}")
on(master, "mount -osize=10m tmpfs #{tmpfs_path} -t tmpfs")

step 'Create Large Binary File'
create_remote_file(master, File.join(git_environments_path, '.gitattributes'), '*.file binary')
on(master, "mkdir -p #{test_files_path}")
on(master, "#{file_bucket_command_path} -s 11 -f #{test_files_path}/test.file -d #{pattern_file_path}")

step 'Push Changes'
git_add_commit_push(master, 'production', 'Add large file.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
