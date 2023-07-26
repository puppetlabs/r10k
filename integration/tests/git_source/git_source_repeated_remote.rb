require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'Verify the same remote can be used in more than one object'

env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)
git_environments_path = '/root/environments'
git_repo_path = '/git_repos'
git_repo_name = 'environments'
git_control_remote = File.join(git_repo_path, "#{git_repo_name}.git")
code_dir = "#{env_path}/production"

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

# Install the same module in two different places
puppetfile = <<-EOS
mod 'prod_apache',
  :git => 'https://github.com/puppetlabs/puppetlabs-apache.git',
  :tag => 'v6.0.0'

mod 'test_apache',
  :git => 'https://github.com/puppetlabs/puppetlabs-apache.git',
  :tag => 'v6.0.0'
EOS

teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Ask r10k to deploy'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Add puppetfile with repeated remote'
create_remote_file(master, "#{git_environments_path}/Puppetfile", puppetfile)
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

step 'Deploy r10k'
on(master, "#{r10k_fqp} deploy environment -p")

step 'Verify module was installed in both places'
on(master, "test -d #{code_dir}/modules/prod_apache")
on(master, "test -d #{code_dir}/modules/test_apache")
