require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-256 - C98049 - verify if non-module content is at root of dir, does not cause erroneous purging'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)
git_environments_path = '/root/environments'
git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
code_dir = '/etc/puppetlabs/code/environments/production'

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

puppetfile = <<-EOS
mod 'non_module_object_1',
  :install_path => './',
  :git => 'https://github.com/puppetlabs/control-repo.git',
  :branch => 'production'

mod 'non_module_object_2',
 :install_path => '',
 :git => 'https://github.com/puppetlabs/control-repo.git',
  :branch => 'production'
EOS

puppetfile_2 = <<-EOS
mod 'puppetlabs-motd'
EOS

teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

step 'Stub the forge'
stub_forge_on(master)

step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Ask r10k to deploy'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Add puppetfile with non-module content at top of directory'
create_remote_file(master, "#{git_environments_path}/Puppetfile", puppetfile)
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

step 'Deploy r10k'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Add puppetfile #2'
create_remote_file(master, "#{git_environments_path}/Puppetfile", puppetfile_2)
git_add_commit_push(master, 'production', 'add Puppetfile to production', git_environments_path)

step 'Deploy r10k after adding puppetfile #2'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Verify that non-module object 1 has not been purged'
on(master, "test -d #{code_dir}/non_module_object_1", :accept_all_exit_codes => true) do |result|
  non_module_error = 'Non-module object was purged; should have been left alone'
  assert(result.exit_code == 0, non_module_error)
end

step 'Verify that non-module object 2 has not been purged'
on(master, "test -d #{code_dir}/non_module_object_2", :accept_all_exit_codes => true) do |result|
  non_module_error = 'Non-module object was purged; should have been left alone'
  assert(result.exit_code == 0, non_module_error)
end
