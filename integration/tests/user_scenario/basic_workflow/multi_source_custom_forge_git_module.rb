require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-85 - C59227 - Multiple Environments with Multiple Sources and Custom, Forge and Git Modules'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
r10k_fqp = get_r10k_fqp(master)

git_provider = ENV['GIT_PROVIDER'] || 'shellgit'

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#Verification
motd_path = '/etc/motd'
motd_contents = 'Hello!'
motd_contents_regex = /\A#{motd_contents}\z/

stdlib_notify_message_regex = /The test message is:.*one.*=>.*1.*two.*=>.*bats.*three.*=>.*3.*/

#Manifest
prod_env_manifest = <<-MANIFEST
  class { 'helloworld': }
  class { 'motd':
    content => '#{motd_contents}',
  }
MANIFEST

stage_env_manifest = <<-MANIFEST
  class { 'helloworld': }
  $hash1 = {'one' => 1, 'two' => 2}
  $hash2 = {'two' => 'bats', 'three' => 3}
  $merged_hash = merge($hash1, $hash2)
  notify { 'Test Message':
    message  => "The test message is: ${merged_hash}"
  }
MANIFEST

#Environment Structures
GitEnv = Struct.new(:repo_path,
                    :repo_name,
                    :control_remote,
                    :environments_path,
                    :puppet_file_path,
                    :puppet_file,
                    :site_pp_path,
                    :site_pp)

env_structs = {:production => GitEnv.new('/git_repos',
                                         'environments',
                                         '/git_repos/environments.git',
                                         '/root/environments',
                                         '/root/environments/Puppetfile',
                                         'mod "puppetlabs/motd"',
                                         '/root/environments/manifests/site.pp',
                                         create_site_pp(master_certname, prod_env_manifest)
                                        ),
               :stage      => GitEnv.new('/git_repos_alt',
                                         'environments_alt',
                                         '/git_repos_alt/environments_alt.git',
                                         '/root/environments_alt',
                                         '/root/environments_alt/Puppetfile',
                                         'mod "puppetlabs/stdlib", :git => "https://github.com/puppetlabs/puppetlabs-stdlib.git", :tag => "v7.0.1"',
                                         '/root/environments_alt/manifests/site.pp',
                                         create_site_pp(master_certname, stage_env_manifest)
                                        ),
              }

last_commit = git_last_commit(master, env_structs[:production].environments_path)

#In-line files
r10k_conf = <<-CONF
cachedir: '/var/cache/r10k'
git:
  provider: '#{git_provider}'
sources:
  control:
    basedir: "#{env_path}"
    remote: "#{env_structs[:production].control_remote}"
  alt_control:
    basedir: "#{env_path}"
    remote: "#{env_structs[:stage].control_remote}"
CONF

#Teardown
teardown do
  step 'Remove "/etc/motd" File'
  on(agents, "rm -rf #{motd_path}")

  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Alternate Git Source'
  on(master, "rm -rf #{env_structs[:stage].repo_path} #{env_structs[:stage].environments_path}")

  clean_up_r10k(master, last_commit, env_structs[:production].environments_path)
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Create Alternate Git Repo and Clone'
init_r10k_source_from_prod(master,
                           env_structs[:stage].repo_path,
                           env_structs[:stage].repo_name,
                           env_structs[:stage].environments_path,
                           'stage'
                          )

env_structs.each do |env_name, env_info|
  step "Checkout \"#{env_name}\" Branch"
  git_on(master, "checkout #{env_name}", env_info.environments_path)

  step "Copy \"helloworld\" Module to \"#{env_name}\" Environment Git Repo"
  scp_to(master, helloworld_module_path, File.join(env_info.environments_path, "site", 'helloworld'))

  step "Inject New \"site.pp\" to the \"#{env_name}\" Environment"
  inject_site_pp(master, env_info.site_pp_path, env_info.site_pp)

  step "Update the \"#{env_name}\" Environment with Puppetfile"
  create_remote_file(master, env_info.puppet_file_path, env_info.puppet_file)

  step "Push Changes to \"#{env_name}\" Environment"
  git_add_commit_push(master, env_name, 'Update site.pp, modules, Puppetfile.', env_info.environments_path)
end

#Tests
step 'Deploy Environments via r10k'
on(master, "#{r10k_fqp} deploy environment -v -p")

agents.each do |agent|
  step 'Run Puppet Agent Against "production" Environment'
  on(agent, puppet('agent', '--test', '--environment production'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/I am in the production environment/, result.stdout, 'Expected message not found!')
  end

  step "Verify MOTD Contents"
  on(agent, "cat #{motd_path}") do |result|
    assert_match(motd_contents_regex, result.stdout, 'File content is invalid!')
  end

  step 'Run Puppet Agent Against "stage" Environment'
  on(agent, puppet('agent', '--test', '--environment stage'), :acceptable_exit_codes => 2) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/I am in the stage environment/, result.stdout, 'Expected message not found!')
    assert_match(stdlib_notify_message_regex, result.stdout, 'Expected message not found!')
  end
end
