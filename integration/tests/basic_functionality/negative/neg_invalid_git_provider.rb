test_name 'CODEMGMT-137 - C64161 - Specify Invalid Value for Git Provider'

#Init
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip

git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')
git_provider = 'invalid'

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

#Verification
error_message_regex = /ConfigError:.*Couldn't load config file/

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
