require 'erb'
require 'securerandom'
require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'CODEMGMT-85 - C59240 - Multiple Sources with Multiple Branches'

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
env_path = on(master, puppet('config print environmentpath')).stdout.rstrip

git_provider = ENV['GIT_PROVIDER'] || 'shellgit'

local_files_root_path = ENV['FILES'] || 'files'
helloworld_module_path = File.join(local_files_root_path, 'modules', 'helloworld')

r10k_config_path = get_r10k_config_file_path(master)
r10k_config_bak_path = "#{r10k_config_path}.bak"

#Sources and environments structures
sources = []
GitEnv = Struct.new(:repo_path,
                    :repo_name,
                    :control_remote,
                    :environments_path,
                    :site_pp_path,
                    :site_pp,
                    :env_names
                   )

#Push default source as first element
sources.push(GitEnv.new('/git_repos',
                        'control',
                        '/git_repos/environments.git',
                        '/root/environments',
                        '/root/environments/manifests/site.pp',
                        create_site_pp(master_certname, '  include helloworld'),
                        (0 ... 10).to_a.map!{ |x| x > 0 ? SecureRandom.uuid.gsub(/-/,"") : 'production'}
                       )
            )

#Generate the remaining environments
(0..9).each do
  source_name = SecureRandom.uuid.gsub(/-/,"")
  sources.push(GitEnv.new("/tmp/git_repo_#{source_name}",
                          "environments_#{source_name}",
                          "/tmp/git_repo_#{source_name}/environments_#{source_name}.git",
                          "/root/environments_#{source_name}",
                          "/root/environments_#{source_name}/manifests/site.pp",
                          create_site_pp(master_certname, '  include helloworld'),
                          (0 ... 10).to_a.map!{ SecureRandom.uuid.gsub(/-/,"") }
                         )
              )
end

#ERB Template
r10k_conf_template_path = File.join(local_files_root_path, 'r10k_conf.yaml.erb')
r10k_conf = ERB.new(File.read(r10k_conf_template_path)).result(binding)

#Teardown
last_commit = git_last_commit(master, sources.first.environments_path)
teardown do
  step 'Restore Original "r10k" Config'
  on(master, "mv #{r10k_config_bak_path} #{r10k_config_path}")

  step 'Remove Git Sources'
  sources.slice(1, sources.length).each do |source|
    on(master, "rm -rf #{source.repo_path} #{source.environments_path}")
  end

  clean_up_r10k(master, last_commit, sources.first.environments_path)
end

#Setup
step 'Backup Current "r10k" Config'
on(master, "mv #{r10k_config_path} #{r10k_config_bak_path}")

step 'Update the "r10k" Config'
create_remote_file(master, r10k_config_path, r10k_conf)

step 'Create Git Sources'
sources.slice(1, sources.length).each do |source|
  init_r10k_source_from_prod(master,
                             source.repo_path,
                             source.repo_name,
                             source.environments_path,
                             source.env_names.first
                            )
end

#Create environments for sources
sources.each do |source|
  source.env_names.each do |env_name|
    if env_name == source.env_names.first
      step "Checkout \"#{env_name}\" Branch"
      git_on(master, "checkout #{env_name}", source.environments_path)

      step "Copy \"helloworld\" Module to \"#{env_name}\" Environment Git Repo"
      scp_to(master, helloworld_module_path, File.join(source.environments_path, "site", 'helloworld'))

      step "Inject New \"site.pp\" to the \"#{env_name}\" Environment"
      inject_site_pp(master, source.site_pp_path, source.site_pp)

      step "Push Changes to \"#{env_name}\" Environment"
      git_add_commit_push(master, env_name, 'Update site.pp and add module.', source.environments_path)
    else
      step "Create \"#{env_name}\" Branch from \"#{source.env_names.first}\""
      git_on(master, "checkout #{source.env_names.first}", source.environments_path)
      git_on(master, "checkout -b #{env_name}", source.environments_path)

      step "Push Changes to \"#{env_name}\" Environment"
      git_push(master, env_name, source.environments_path)
    end
  end
end

#Tests
step 'Deploy Environments via r10k'
on(master, 'r10k deploy environment -v')

#Select three environments at random and verify results.
sources.sample(3).each do |source|
  source.env_names.sample(1).each do |env_name|
    agents.each do |agent|
      step "Run Puppet Agent Against \"#{env_name}\" Environment"
      on(agent, puppet('agent', '--test', "--environment #{env_name}"), :acceptable_exit_codes => 2) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        assert_match(/I am in the #{env_name} environment/, result.stdout, 'Expected message not found!')
      end
    end
  end
end
