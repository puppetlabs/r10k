require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
require 'openssl'
test_name 'CODEMGMT-101 - C59237 - Attempt to Deploy Environment with Unauthorized "SSH" Git Source'
skip_test('test requires resolution of RK-137')

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
git_control_remote = 'git@github.com:puppetlabs/codemgmt-92.git'
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'
r10k_fqp = get_r10k_fqp(master)

unauthorized_rsa_key = OpenSSL::PKey::RSA.new(2048)
ssh_private_key_path = '/root/.ssh/unauthorized_key'
ssh_config_path = '/root/.ssh/config'

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
  private_key: '#{ssh_private_key_path}'
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
error_message_regex = /ERROR.*Unable to determine current branches for Git source 'broken'/m

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Unauthorized SSH Key'
  on(master, "rm -rf #{ssh_private_key_path}")

  step 'Remove SSH Config'
  on(master, "rm -rf #{ssh_config_path}")
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Copy Unauthorized SSH Key to Master'
create_remote_file(master, ssh_config_path, ssh_config)
on(master, "chmod 600 #{ssh_config_path}")

step 'Configure SSH to Use Unauthorized SSH Key for "github.com"'
create_remote_file(master, ssh_private_key_path, unauthorized_rsa_key)
on(master, "chmod 600 #{ssh_private_key_path}")

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment -v", :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
