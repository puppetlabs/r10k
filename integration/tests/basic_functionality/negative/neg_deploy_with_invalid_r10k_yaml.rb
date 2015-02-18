require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-84 - C59271 - Attempt to Deploy with Invalid r10k Config'

#Init
r10k_config_path = '/etc/r10k.yaml'
r10k_config_bak_path = "#{r10k_config_path}.bak"

#In-line files
r10k_conf = <<-CONF
sources:
  broken:
    dir: "#{env_path}"
    remote: "#{git_control_remote}"
CONF

#Verification
error_message_regex = /ERROR.*can\'t\ convert\ nil\ into\ String/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")
end

#Setup
step 'Backup a Valid "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v', :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
