require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-256 - C98013 - verify default purging behavior'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)
git_environments_path = '/root/environments'
git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")

last_commit = git_last_commit(master, git_environments_path)
git_provider = ENV['GIT_PROVIDER']
r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"
#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

# initialize path name a....d (where it is)
code_dir_path = '/etc/puppetlabs/code'
fake_environment_path_a = [code_dir_path, 'environments'].join('/')
fake_environment_path_b = [code_dir_path,'environments', 'production'].join('/')
fake_environment_path_c = [code_dir_path, 'environments', 'production', 'modules'].join('/')
fake_environment_path_d = [code_dir_path, 'environments', 'production', 'modules', 'motd'].join('/')  #not sure if need

# initalize directory name a...c (where it is, what it is called)
fake_dir_a_to_be_purged     = "#{fake_environment_path_a}/fakedir1"
fake_dir_b_to_be_left_alone = "#{fake_environment_path_b}/fakedir2"
fake_dir_c_to_be_purged     = "#{fake_environment_path_c}/fakedir3"

# initalize file name a...c (where it is, what it is called)
fake_file_a_to_be_purged     = "#{fake_environment_path_a}/fakefile1.txt"
fake_file_b_to_be_left_alone = "#{fake_environment_path_b}/fakefile2.txt"
fake_file_c_to_be_purged     = "#{fake_environment_path_c}/fakefile3.txt"

# initalize file content
step 'Stub the forge'
stub_forge_on(master)

step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Create content to be managed by r10k'
git_on(master, 'checkout production', git_environments_path)
create_remote_file(master, "#{git_environments_path}/Puppetfile", 'mod "puppetlabs-motd"')
git_add_commit_push(master, 'production', 'add Puppetfile to production', git_environments_path)

git_on(master, 'checkout production', git_environments_path)
git_on(master, 'checkout -b cats', git_environments_path)
create_remote_file(master, "#{git_environments_path}/Puppetfile", 'mod "puppetlabs-inifile"')
git_add_commit_push(master, 'cats', 'add Puppetfile to cats', git_environments_path)

step 'Ask r10k to deploy'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Create fake file and directory at deployment level to be purged'
create_remote_file(master, fake_file_a_to_be_purged, "foobar nonsense")
on(master, "mkdir #{fake_dir_a_to_be_purged}")

step 'Create fake file and directory at environment level to be left alone'
create_remote_file(master, fake_file_b_to_be_left_alone, "foobar nonsense")
on(master, "mkdir #{fake_dir_b_to_be_left_alone}")

step 'Create fake file and directory at puppetfile level to be purged '
create_remote_file(master, fake_file_c_to_be_purged, "foobar nonsense")
on(master, "mkdir #{fake_dir_c_to_be_purged}")

step('Deploy r10k')
on(master, "#{r10k_fqp} deploy environment -p")

step('validate if files/directories were purged/kept')

step('Assert to see if deployment level file and directory were purged')
on(master, "ls #{fake_environment_path_a} | wc -l") do |result|
  assert_match(/2/, result.stdout, 'error: purge not successful')
end

step('Assert to see if environment level file and directory were not purged')
on(master,"ls #{fake_environment_path_b} | wc -l" ) do |result|
  assert_match(/7/, result.stdout, 'error: purge not successful')
end

step('Assert to see if puppetfile level level file and directory were purged')
on(master,"ls #{fake_environment_path_c} | wc -l" ) do |result|
  assert_match(/1/, result.stdout, 'error: purge not successful')
end

step('Assert to see if deployment level file is not there')
on(master, "test -f #{fake_file_a_to_be_purged}", :accept_all_exit_codes => true) do |result|
  file_a_error = 'Puppet file purging was not observed'
  assert(result.exit_code == 1, file_a_error)
end

step('Assert to see if deployment level directory is not there')
on(master, "test -d #{fake_dir_a_to_be_purged}", :accept_all_exit_codes => true) do |result|
  dir_a_error = 'Puppet directory purging was not observed'
  assert(result.exit_code == 1, dir_a_error)
end

step('Assert to see if environment level file is still there after second deployment')
on(master, "test -f #{fake_file_b_to_be_left_alone}", :accept_all_exit_codes => true) do |result|
  file_b_error = 'Puppet file purging deleted this file when it should have left it alone :('
  assert(result.exit_code == 0, file_b_error)
end

step('Assert to see if environment level directory is still there after second deployment')
on(master, "test -d #{fake_dir_b_to_be_left_alone}", :accept_all_exit_codes => true) do |result|
  dir_b_error = 'Puppet directory purging deleted this directory when it should have left it alone :('
  assert(result.exit_code == 0, dir_b_error)
end

step('Assert to see if puppetfile level file is not there')
on(master, "test -f #{fake_file_c_to_be_purged}", :accept_all_exit_codes => true) do |result|
  file_c_error = 'Puppet file purging was not observed'
  assert(result.exit_code == 1, file_c_error)
end

step('Assert to see if puppetfile level directory is not there')
on(master, "test -d #{fake_dir_c_to_be_purged}", :accept_all_exit_codes => true) do |result|
  dir_c_error = 'Puppet directory purging was not observed'
  assert(result.exit_code == 1, dir_c_error)
end
