require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
require 'beaker-qa-i18n'

test_name 'Deploy module with unicode file name'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')
r10k_fqp = get_r10k_fqp(master)

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Verification
notify_message_regex = /I am in the production environment/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

test_i18n_strings(10, [:syntax, :white_space]) do |test_string|
  #Setup
  test_file_path = File.join(git_environments_path, "site", 'helloworld', 'manifests', test_string)

  step 'Checkout "production" Branch'
  git_on(master, 'checkout production', git_environments_path)

  step 'Copy "helloworld" Module to "production" Environment Git Repo'
  scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

  step 'Add unicode file to helloworld Module'
  create_remote_file(master, test_file_path, 'test file contents')

  step 'Inject New "site.pp" to the "production" Environment'
  inject_site_pp(master, site_pp_path, site_pp)

  step 'Push Changes'
  git_add_commit_push(master, 'production', 'Update site.pp and add module.', git_environments_path)

  #Tests
  step 'Deploy "production" Environment via r10k'
  on(master, "#{r10k_fqp} deploy environment -v")

  step 'test deployment of Unicode file'
  deployed_test_file_path = "/etc/puppetlabs/code/environments/production/site/helloworld/manifests/#{test_string}"
  on(master, "test -f #{deployed_test_file_path}", :accept_all_exit_codes => true) do |result|
    assert(result.exit_code == 0, "The unicode test file #{test_string} was not deployed by r10k")
  end

  agents.each do |agent|
    step "Run Puppet Agent"
    on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(notify_message_regex, result.stdout, 'Expected message not found!')
    end
  end
end
