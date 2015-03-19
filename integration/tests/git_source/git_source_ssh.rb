require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-92 - C59234 - Single Git Source Using "SSH" Transport Protocol'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
git_control_remote = 'git@github.com:puppetlabs/codemgmt-92.git'

jenkins_key_path = File.file?('/var/lib/jenkins/.ssh/id_rsa-jenkins') ? '/var/lib/jenkins/.ssh/id_rsa-jenkins' : File.expand_path('~/.ssh/id_rsa-jenkins')
ssh_private_key_path = '/root/.ssh/id_rsa-jenkins'
ssh_config_path = '/root/.ssh/config'

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
sources:
  broken:
    basedir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

ssh_config = <<-CONF
StrictHostKeyChecking no

Host github.com
    IdentityFile #{ssh_private_key_path}
CONF

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Jenkins SSH Key'
  on(master, "rm -rf #{ssh_private_key_path}")

  step 'Remove SSH Config'
  on(master, "rm -rf #{ssh_config_path}")

  step 'Restore Original "production" Environment via r10k'
  on(master, 'r10k deploy environment -v')
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

if File.file?(jenkins_key_path) == false
  skip_test('Skipping test because necessary SSH key is not present!')
end

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Configure SSH to Use SSH Key for "github.com"'
create_remote_file(master, ssh_config_path, ssh_config)
on(master, "chmod 600 #{ssh_config_path}")

step 'Copy SSH Key to Master'
scp_to(master, jenkins_key_path, ssh_private_key_path)
on(master, "chmod 600 #{ssh_private_key_path}")

#Tests
step 'Deploy "production" Environment via r10k'
on(master, 'r10k deploy environment -v')

agents.each do |agent|
  step "Run Puppet Agent"
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
