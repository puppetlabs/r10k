require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-730 - C97977 - Specify HTTP_PROXY environment var and proxy for specific git source'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
git_provider = ENV['GIT_PROVIDER']

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

puppetfile =<<-EOS
mod 'motd',
  :git => 'https://github.com/puppetlabs/puppetlabs-motd', :branch => 'main'
EOS

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
  repositories:
    - remote: 'https://something.else/repo'
      proxy: 'http://foooooooo.unresolvable:3128'
sources:
  control:
    basedir: "#{env_path}"
    remote: 'https://something.else/repo'
CONF

teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'cleanup r10k'
  clean_up_r10k(master, last_commit, git_environments_path)
end

step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy Puppetfile to "production" Environment Git Repo'
create_remote_file(master, "#{git_environments_path}/Puppetfile", puppetfile)

step 'Push Changes'
git_add_commit_push(master, 'production', 'add Puppetfile', git_environments_path)

#test
on(master, "#{r10k_fqp} deploy environment -p", :accept_all_exit_codes => true) do |r|
  # Rugged as of 0.28 has a different error message than shellgit
  regex = /((failed to resolve address for)|(Could not resolve proxy:)) foooooooo\.unresolvable/
  assert(r.exit_code == 1, 'expected error code was not observed')
  assert_match(regex, r.stderr, 'The expected error message was not observed' )
end
