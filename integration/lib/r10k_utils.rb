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

  step 'Reset Git Repo to Known Good State'
  git_revert_environment(master, commit_sha, git_repo_path)

  step 'Restore Original "production" Environment'
  on(master, 'r10k deploy environment -v')

  step 'Verify "production" Environment is at Original State'
  verify_production_environment(master)

  step 'Remove Any Modules from the "production" Environment'
  on(agents, "rm -rf #{prod_env_modules_path}/*")
end
