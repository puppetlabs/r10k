require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'


test_name 'Basic Environment Deployment Workflows'

# This isn't a block because we want to use the local variables throughout the file
step 'init'
  env_path              = on(master, puppet('config print environmentpath')).stdout.rstrip
  r10k_fqp              = get_r10k_fqp(master)

  control_repo_gitdir   = '/git_repos/environments.git'
  control_repo_worktree = '/root/environments'
  last_commit           = git_last_commit(master, control_repo_worktree)
  git_provider          = ENV['GIT_PROVIDER']

  config_path           = get_r10k_config_file_path(master)
  config_backup_path    = "#{config_path}.bak"

  puppetfile1 =<<-EOS
    mod 'puppetlabs/apache', '0.10.0'
    mod 'puppetlabs/stdlib', '8.0.0'
    EOS

  r10k_conf = <<-CONF
    cachedir: '/var/cache/r10k'
    git:
      provider: '#{git_provider}'
    sources:
      control:
        basedir: "#{env_path}"
        remote: "#{control_repo_gitdir}"
    deploy:
      purge_levels: ['deployment','environment','puppetfile']

    CONF


def and_stdlib_is_correct
  metadata_path = "#{env_path}/production/modules/stdlib/metadata.json"
  on(master, "test -f #{metadata_path}", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'stdlib content has been inappropriately purged')
  end
  metadata_info = JSON.parse(on(master, "cat #{metadata_path}").stdout)
  assert(metadata_info['version'] == '8.0.0', 'stdlib deployed to wrong version')
end

teardown do
  on(master, "mv #{config_backup_path} #{config_path}")
  clean_up_r10k(master, last_commit, control_repo_worktree)
end

step 'Set up r10k and control repo' do

  # Backup and replace r10k config
  on(master, "mv #{config_path} #{config_backup_path}")
  create_remote_file(master, config_path, r10k_conf)

  # Place our Puppetfile in the control repo's production branch
  git_on(master, 'checkout production', control_repo_worktree)
  create_remote_file(master, "#{control_repo_worktree}/Puppetfile", puppetfile1)
  git_add_commit_push(master, 'production', 'add Puppetfile for Basic Deployment test', control_repo_worktree)

end

test_path = "#{env_path}/production/modules/apache/metadata.json"
step 'Test initial environment deploy works' do
  on(master, "#{r10k_fqp} deploy environment production --verbose=info") do |result|
    assert(result.stdout =~ /.*Deploying module to .*apache.*/, 'Did not log apache deployment')
    assert(result.stdout =~ /.*Deploying module to .*stdlib.*/, 'Did not log stdlib deployment')
  end
  on(master, "test -f #{test_path}", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Expected module in Puppetfile was not installed')
  end

  and_stdlib_is_correct
end

original_apache_info = JSON.parse(on(master, "cat #{test_path}").stdout)

step 'Test second run of deploy updates control repo, but not modules' do
  puppetfile2 =<<-EOS
    mod 'puppetlabs/apache', :latest
    mod 'puppetlabs/stdlib', '8.0.0'
    EOS

  git_on(master, 'checkout production', control_repo_worktree)
  create_remote_file(master, "#{control_repo_worktree}/Puppetfile", puppetfile2)
  git_add_commit_push(master, 'production', 'add Puppetfile for Basic Deployment test', control_repo_worktree)

  on(master, "#{r10k_fqp} deploy environment production --verbose=info") do |result|
    refute(result.stdout =~ /.*Deploying module to .*apache.*/, 'Inappropriately updated apache')
    refute(result.stdout =~ /.*Deploying module to .*stdlib.*/, 'Inappropriately updated stdlib')
  end
  on(master, "test -f #{test_path}", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Expected module content in Puppetfile was inappropriately purged')
  end

  new_apache_info = JSON.parse(on(master, "cat #{test_path}").stdout)
  on(master, "cat #{env_path}/production/Puppetfile | grep 5.0.0", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Puppetfile not updated on subsequent r10k deploys')
  end

  assert(original_apache_info['version'] == new_apache_info['version'] &&
         new_apache_info['version'] == '0.10.0',
         'Module content updated on subsequent r10k invocations w/o providing --modules')

  and_stdlib_is_correct
end

step 'Test --modules updates modules' do
  on(master, "#{r10k_fqp} deploy environment production --modules --verbose=info") do |result|
    assert(result.stdout =~ /.*Deploying module to .*apache.*/, 'Did not log apache deployment')
    assert(result.stdout =~ /.*Deploying module to .*stdlib.*/, 'Did not log stdlib deployment')
  end
  on(master, "test -f #{test_path}", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Expected module content in Puppetfile was inappropriately purged')
  end

  new_apache_info = JSON.parse(on(master, "cat #{test_path}").stdout)
  apache_major_version = new_apache_info['version'].split('.').first.to_i
  assert(apache_major_version > 5, 'Module not updated correctly using --modules')

  and_stdlib_is_correct
end

step 'Test --modules --incremental updates changed modules' do
  on(master, "#{r10k_fqp} deploy environment production --modules --incremental --verbose=debug1") do |result|
    assert(result.stdout =~ /.*Deploying module to .*apache.*/, 'Did not log apache deployment')
    assert(result.stdout =~ /.*Not updating module stdlib, assuming content unchanged.*/, 'Did not log notice of skipping stdlib')
  end
  on(master, "test -f #{test_path}", accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Expected module content in Puppetfile was inappropriately purged')
  end

  new_apache_info = JSON.parse(on(master, "cat #{test_path}").stdout)
  apache_major_version = new_apache_info['version'].split('.').first.to_i
  assert(apache_major_version > 5, 'Module not updated correctly using --modules & --incremental')

  and_stdlib_is_correct
end


