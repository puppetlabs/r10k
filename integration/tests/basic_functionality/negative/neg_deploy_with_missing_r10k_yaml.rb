require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-84 - C59270 - Attempt to Deploy with Missing r10k Configuration File'

#Init
r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"
r10k_fqp = get_r10k_fqp(master)

#Verification
error_message_regex = /No configuration file given, no config file found in current directory, and no global config present/

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment -v", :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
