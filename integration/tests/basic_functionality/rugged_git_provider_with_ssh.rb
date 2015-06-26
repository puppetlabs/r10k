require 'erb'
require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-137 - C64160 - Use "rugged" Git Provider with Authentication'

confine(:to, :platform => ['el', 'ubuntu', 'sles'])

if ENV['GIT_PROVIDER'] == 'shellgit'
  skip_test('Skipping test because removing Git from the system affects other "shellgit" tests.')
elsif fact_on(master, 'osfamily') == 'RedHat' and fact_on(master, "operatingsystemmajrelease").to_i < 6
  skip_test('This version of EL is not supported by this test case!')
end

#Init
master_platform = fact_on(master, 'osfamily')
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)

git_repo_path = '/git_repos'
git_control_remote = 'git@github.com:puppetlabs/codemgmt-92.git'
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
git_provider = 'rugged'

jenkins_key_path = File.file?("#{ENV['HOME']}/.ssh/id_rsa") ? "#{ENV['HOME']}/.ssh/id_rsa" : File.expand_path('~/.ssh/id_rsa-jenkins')
ssh_private_key_path = '/root/.ssh/id_rsa-jenkins'

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

git_manifest_template_path = File.join(local_files_root_path, 'pre-suite', 'git_config.pp.erb')
git_manifest = ERB.new(File.read(git_manifest_template_path)).result(binding)

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
  private_key: '#{ssh_private_key_path}'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  step 'Restore "git" Package'
  on(master, puppet('apply'), :stdin => git_manifest, :acceptable_exit_codes => [0,2])

  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

if File.file?(jenkins_key_path) == false
  skip_test('Skipping test because necessary SSH key is not present!')
end

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Copy SSH Key to Master'
scp_to(master, jenkins_key_path, ssh_private_key_path)
on(master, "chmod 600 #{ssh_private_key_path}")

step 'Remove "git" Package from System'
if master_platform == 'RedHat'
  on(master, 'yum remove -y git')
elsif master_platform == 'Debian'
  if fact_on(master, "operatingsystemmajrelease") == '10.04'
    on(master, 'apt-get remove -y git-core')
  else
    on(master, 'apt-get remove -y git')
  end
elsif master_platform == 'SLES'
  on(master, 'zypper remove -y git-core git')
end

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
