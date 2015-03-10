require 'git_utils'

# Verify that a pristine "production" environment exists on the master.
# (And only the "production" environment!)
#
# ==== Attributes
#
# * +master+ - The Puppet master on which to verify the "production" environment.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# verify_production_environment(master)
def verify_production_environment(master)
  environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
  prod_env_md5sum_path = File.join(environment_path, 'production', 'manifests', '.site_pp.md5')

  #Verify MD5 sum of "site.pp"
  on(master, "md5sum -c #{prod_env_md5sum_path}")

  #Verify that "production" is the only environment available.
  on(master, "test `ls #{environment_path} | wc -l` -eq 1")
  on(master, "ls #{environment_path} | grep \"production\"")
end

# Clean-up the r10k environment on the master to bring it back to a known good state.
#
# ==== Attributes
#
# * +host+ - The Puppet master on which to verify the "production" environment.
# * +commit_sha+ - The reset HEAD to this commit SHA.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# clean_up_r10k(master, 'ff81c01c5', '~/git_repo')
def clean_up_r10k(master, commit_sha, git_repo_path)
  environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
  prod_env_modules_path = File.join(environment_path, 'production', 'modules')
  prod_env_site_path = File.join(environment_path, 'production', 'site')

  step 'Reset Git Repo to Known Good State'
  git_revert_environment(master, commit_sha, git_repo_path)

  step 'Restore Original "production" Environment'
  on(master, 'r10k deploy environment -v')

  step 'Verify "production" Environment is at Original State'
  verify_production_environment(master)

  step 'Remove Any Modules from the "production" Environment'
  on(master, "rm -rf #{prod_env_modules_path}/*")
  on(master, "rm -rf #{prod_env_site_path}/*")
end

# Create a new r10k Git source that is copied from the current "production" environment.
#
# ==== Attributes
#
# * +master+ - The Puppet master on which to create a new Git source.
# * +git_repo_parent_path+ - The parent path that contains the desired Git repository.
# * +git_repo_name+ - The name of the repository.
# * +git_clone_path+ - The destination path for the git clone.
# * +env_name+ - The initial branch name (environment) for first commit.
# * +deploy?+ - A flag indicating if r10k environment deployment should be kicked off after cloning.
#
# ==== Returns
#
# +string+ - The path to the newly created Git repository.
#
# ==== Examples
#
# init_r10k_source_from_prod(master, '/git/repos', 'environments', '~/repos/r10k', 'test', deploy=true)
def init_r10k_source_from_prod(master, git_repo_parent_path, git_repo_name, git_clone_path, env_name, deploy=false)
  #Init
  env_path = on(master, puppet('config print environmentpath')).stdout.rstrip
  prod_env_path = File.join(env_path, 'production')

  local_files_root_path = ENV['FILES'] || 'files'
  prod_env_config_path = 'pre-suite/prod_env.config'
  prod_env_config = File.read(File.join(local_files_root_path, prod_env_config_path))

  #Create Git origin repo and clone.
  git_init_bare_repo_and_clone(master, git_repo_parent_path, git_repo_name, git_clone_path)

  #Copy current contents of production environment to the git clone path
  on(master, "cp -r #{prod_env_path}/* #{git_clone_path}")

  #Create hidden files in the "site" and "modules" folders so that git copies the directories.
  on(master, "mkdir -p #{git_clone_path}/modules #{git_clone_path}/site")
  on(master, "touch #{git_clone_path}/modules/.keep;touch #{git_clone_path}/site/.keep")

  #Create MD5 sum file for the "site.pp" file.
  on(master, "md5sum #{git_clone_path}/manifests/site.pp > #{git_clone_path}/manifests/.site_pp.md5")

  #Add environment config that specifies module lookup path for production.
  create_remote_file(master, "#{git_clone_path}/environment.conf", prod_env_config)
  git_on(master, "add #{git_clone_path}/*", git_clone_path)
  git_on(master, "commit -m \"Add #{env_name} environment.\"", git_clone_path)
  git_on(master, "branch -m #{env_name}", git_clone_path)
  git_on(master, "push -u origin #{env_name}", git_clone_path)

  #Attempt to deploy environments.
  if deploy
    on(master, 'r10k deploy environment -v')
  end
end
