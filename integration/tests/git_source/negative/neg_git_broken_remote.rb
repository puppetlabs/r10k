require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
require 'digest/sha1'
test_name 'CODEMGMT-101 - C59261 - Attempt to Deploy Environment with Broken Git Remote'

#Init
git_control_remote = '/git_repos/environments.git'
prod_branch_head_ref_path = File.join(git_control_remote, 'refs', 'heads', 'production')
prod_branch_head_ref_path_backup = '/tmp/production.bak'

invalid_sha_ref = Digest::SHA1.hexdigest('broken')

#Verification
error_message_regex = /ERROR\].*Blah/m

#Teardown
teardown do
  step 'Restore Original "production" Branch Head Ref'
  on(master, "mv #{prod_branch_head_ref_path_backup} #{prod_branch_head_ref_path}")
end

#Setup
step 'Backup Current "production" Branch Head Ref'
on(master, "mv #{prod_branch_head_ref_path} #{prod_branch_head_ref_path_backup}")

step 'Inject Corrupt "production" Branch Head Ref'
create_remote_file(master, prod_branch_head_ref_path, "#{invalid_sha_ref}\n")
on(master, "chmod 644 #{prod_branch_head_ref_path}")

#Tests
step 'Attempt to Deploy via r10k'
on(master, 'r10k deploy environment -v -t', :acceptable_exit_codes => 0) do |result|
  expect_failure('Expected to fail due to RK-28') do
    assert_match(error_message_regex, result.stderr, 'Expected message not found!')
  end
end
