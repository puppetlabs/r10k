require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-257 - C98046 - r10k does not purge files on allowlist'

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

teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

# initalize file content
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
deploy:
  purge_levels: ['deployment', 'environment', 'puppetfile']
  purge_allowlist: ['**/*.pp']
CONF

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Copy Puppetfile to "production" Environment Git Repo'
create_remote_file(master, "#{git_environments_path}/Puppetfile", "mod 'puppetlabs-stdlib' \n mod 'puppetlabs-motd'")

step 'Push Changes'
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

step 'Deploy production'
on(master, "#{r10k_fqp} deploy environment -p")

step 'commit a new Puppetfile to production'
create_remote_file(master, "#{git_environments_path}/Puppetfile", 'mod "puppetlabs-motd"')

step 'Push Changes'
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

step 'create test pp files'
do_not_purge = [
    "/etc/puppetlabs/code/environments/production/environment_level.pp",
    "/etc/puppetlabs/code/environments/production/site/environment_level.pp"
].each do |file|
  create_remote_file(master, file, 'this is a test')
end

purge = [
    "/etc/puppetlabs/code/environments/production/environment_level.zz",
    "/etc/puppetlabs/code/environments/production/site/environment_level.zz"
].each do |file|
  create_remote_file(master, file, 'this is a test')
end

#TEST
step 'Deploy again and check files'
on(master, "#{r10k_fqp} deploy environment -p")

purge.each do |file|
  assert_message = "The file #{file}\n was not purged, it was expected to be"
  assert(on(master, "test -f #{file}", :accept_all_exit_codes => true).exit_code == 1, assert_message)
end

do_not_purge.each do |file|
  assert_message = "The file #{file}\n was purged, it was not expected to be"
  assert(on(master, "test -f #{file}", :accept_all_exit_codes => true).exit_code == 0, assert_message)
end
