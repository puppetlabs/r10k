require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-92 - C59235 - Single Git Source Using "GIT" Transport Protocol'

confine(:to, :platform => 'el')

if fact_on(master, "os.release.major").to_i < 6 || fact_on(master, "os.release.major").to_i > 8
  skip_test('This version of EL is not supported by this test case!')
end

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)

git_control_remote = 'git://localhost/environments.git'
git_environments_path = '/root/environments'
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'
last_commit = git_last_commit(master, git_environments_path)

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  broken:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

git_daemon_xinetd_enable_manifest = <<-MANIFEST
package { 'git-daemon':
  ensure => present
}
include xinetd
xinetd::service { 'git-daemon':
  port         => '9418',
  server       => '/usr/libexec/git-core/git-daemon',
  server_args  => '--inetd --verbose --syslog --export-all --base-path=/git_repos',
  socket_type  => 'stream',
  user         => 'nobody',
  wait         => 'no',
  service_type => 'UNLISTED',
  disable      => 'no'
}
MANIFEST

git_daemon_xinetd_disable_manifest = <<-MANIFEST
xinetd::service { 'git-daemon':
  port    => '9418',
  server  => '/usr/libexec/git-core/git-daemon',
  disable => 'yes'
}
MANIFEST

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Stop "xinetd" Service'
  on(master, puppet('apply'), :stdin => git_daemon_xinetd_disable_manifest)
  on(master, puppet('resource', 'service', 'xinetd', 'ensure=stopped'))

  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Run Puppet Agent to Clear Plug-in Cache'
  on(agents, puppet('agent', '--test', '--environment production'))
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Install "puppetlabs-xinetd" Module'
on(master, puppet('config print basemodulepath')) do |result|
  (result.stdout.include? ':') ? separator = ':' : separator = ';'
  @module_path = result.stdout.split(separator).first
end
on(master, puppet("module install puppetlabs-xinetd --modulepath #{@module_path}"))

step 'Install and Configure "git-daemon" service'
on(master, puppet('apply'), :stdin => git_daemon_xinetd_enable_manifest)

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Copy "helloworld" Module to "production" Environment Git Repo'
scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

step 'Inject New "site.pp" to the "production" Environment'
inject_site_pp(master, site_pp_path, site_pp)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

#Tests
step 'Deploy "production" Environment via r10k'
on(master, "#{r10k_fqp} deploy environment -v")

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
