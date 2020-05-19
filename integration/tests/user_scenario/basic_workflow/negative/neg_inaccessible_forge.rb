require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-42 - C59256 - Attempt to Deploy Environment with Inaccessible Forge'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
r10k_fqp = get_r10k_fqp(master)

hosts_file_path = '/etc/hosts'

#File
puppet_file = <<-PUPPETFILE
mod "puppetlabs/motd"
PUPPETFILE

puppet_file_path = File.join(git_environments_path, 'Puppetfile')

#Verification
error_message_regex = /Error: Could not connect via HTTPS to https:\/\/forgeapi.puppet.com/

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)

  step 'Restore Original Hosts File'
  on(master, "mv #{hosts_file_path}.bak #{hosts_file_path}")
end

#Setup
step 'Backup "/etc/hosts" File on Master'
on(master, "mv #{hosts_file_path} #{hosts_file_path}.bak")

step 'Point Forge Hostname to Localhost'
on(master, "echo '127.0.0.1  forgeapi.puppet.com' > #{hosts_file_path}")

step 'Checkout "production" Branch'
git_on(master, 'checkout production', git_environments_path)

step 'Create "Puppetfile" for the "production" Environment'
create_remote_file(master, puppet_file_path, puppet_file)

step 'Push Changes'
git_add_commit_push(master, 'production', 'Update Puppetfile.', git_environments_path)

#Tests
step 'Attempt to Deploy via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p", :acceptable_exit_codes => 1) do |result|
  if get_puppet_version(master) > 4.0
    expect_failure('expected to fail due to RK-134') do
      assert_match(error_message_regex, result.stderr, 'Expected message not found!')
    end
  else
    assert_match(error_message_regex, result.stderr, 'Expected message not found!')
  end
end
