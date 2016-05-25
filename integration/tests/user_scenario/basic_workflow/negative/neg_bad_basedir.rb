require 'git_utils'
require 'master_manipulator'
test_name 'CODEMGMT-42 - C59225 - Attempt to Deploy to Base Directory with Invalid Length'

#Init
env_path = '/asuyiyuyabvusayd2784782gh8hexistasdfaiasdhfa78v87va8vajkb3vwkasv7as8vba87vb87asdhfajsbdzxmcbvawbvr7av6baskudvbausdgasycyu7abywfegasfsauydgfasf7uas67vbexistasdfaiasdhfa78v87va8vajkb3vwkasv7as8vba87vb87asdhfajsbdzxmcbvawbvr7av6baskudvbausdgasycyu7abywfegasfsauydgfasf7uas67vb'
git_repo_path = '/git_repos'
git_control_remote = File.join(git_repo_path, 'environments.git')
git_provider = ENV['GIT_PROVIDER'] || 'shellgit'
r10k_fqp = get_r10k_fqp(master)

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

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

#Verification
error_message_regex = /ERROR.*(Failed to make directory|File name too long)/m

#Teardown
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment -v", :acceptable_exit_codes => 1) do |result|
  assert_match(error_message_regex, result.stderr, 'Expected message not found!')
end
