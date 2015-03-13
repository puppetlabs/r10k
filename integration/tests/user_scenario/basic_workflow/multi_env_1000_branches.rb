require 'securerandom'
require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-62 - C59241 - Single Source with 1,000 Branches'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
confdir_path = on(master, puppet('config', 'print', 'confdir')).stdout.rstrip
modules_path = File.join(confdir_path, 'modules')

git_environments_path = '/root/environments'
last_commit = git_last_commit(master, git_environments_path)
local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

#Because of CODEMGMT-64 we can only support 100 branches currently.
env_names = (0 ... 100).to_a.map!{ |x| x > 0 ? SecureRandom.uuid.gsub(/-/,"") * 3 : 'production'}

#Manifest
site_pp_path = File.join(git_environments_path, 'manifests', 'site.pp')
site_pp = create_site_pp(master_certname, '  include helloworld')

#Teardown
teardown do
  clean_up_r10k(master, last_commit, git_environments_path)
end

#Setup
env_names.each do |env|
  if env == 'production'
    step "Checkout \"#{env}\" Branch"
    git_on(master, "checkout #{env}", git_environments_path)

    step "Copy \"helloworld\" Module to \"#{env}\" Environment Git Repo"
    scp_to(master, helloworld_module_path, File.join(git_environments_path, "site", 'helloworld'))

    step "Inject New \"site.pp\" to the \"#{env}\" Environment"
    inject_site_pp(master, site_pp_path, site_pp)

    step "Push Changes to \"#{env}\" Environment"
    git_add_commit_push(master, env, 'Update site.pp.', git_environments_path)
  else
    step "Create \"#{env}\" Branch from \"production\""
    git_on(master, 'checkout production', git_environments_path)
    git_on(master, "checkout -b #{env}", git_environments_path)

    step "Push Changes to \"#{env}\" Environment"
    git_push(master, env, git_environments_path)
  end
end

#Tests
step 'Deploy Environments via r10k'
on(master, 'r10k deploy environment -v')

#Select three environments at random and verify results.
env_names.sample(3).each do |env|
  agents.each do |agent|
    step "Run Puppet Agent Against \"#{env}\" Environment"
    on(agent, puppet('agent', '--test', "--environment #{env}"), :acceptable_exit_codes => 2) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(/I am in the #{env} environment/, result.stdout, 'Expected message not found!')
    end
  end
end
