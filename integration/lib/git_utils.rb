# Execute a git command on a host.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +git_sub_command+ - The git sub-command to execute including arguments. (The 'git' command is assumed.)
# * +git_repo_path+ - The path to the git repository on the target host.
# * +opts+ - Options to alter execution.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_on(master, 'add file.txt', '~/git_repo')
def git_on(host, git_sub_command, git_repo_path, opts = {})
  git_command = "git --git-dir=#{git_repo_path}/.git --work-tree=#{git_repo_path} #{git_sub_command}"

  on(host, git_command, opts)
end

# Add all uncommitted files located in a repository.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_add_everything(master, '~/git_repo')
def git_add_everything(host, git_repo_path)
  git_on(host, "add #{git_repo_path}/*", git_repo_path)
end

# Push branch to origin remote.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +branch+ - The branch to push.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_push(master, 'production', '~/git_repo')
def git_push(host, branch, git_repo_path)
  git_on(host, "push origin #{branch}", git_repo_path)
end

# Commit changes and push branch to origin remote.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +branch+ - The branch to push.
# * +message+ - A single-line commit message. (Don't quote message!)
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_commit_push(master, 'production', 'Awesome stuff!', '~/git_repo')
def git_commit_push(host, branch, message, git_repo_path)
  git_on(host, "commit -m \"#{message}\"", git_repo_path)
  git_push(host, branch, git_repo_path)
end

# Add all uncommitted files located in a repository, commit changes and push branch to origin remote.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +branch+ - The branch to push.
# * +message+ - A single-line commit message. (Don't quote message!)
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_add_commit_push(master, 'production', 'Awesome stuff!', '~/git_repo')
def git_add_commit_push(host, branch, message, git_repo_path)
  git_add_everything(host, git_repo_path)
  git_commit_push(host, branch, message, git_repo_path)
end

# Get the last commit SHA.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +string+ - The SHA of the last commit.
#
# ==== Examples
#
# last_commit = git_last_commit(master, '~/git_repo')
def git_last_commit(host, git_repo_path)
  sha_regex = /commit (\w{40})/

  return sha_regex.match(git_on(host, 'log', git_repo_path).stdout)[1]
end

# Hard reset the git repository to a specific commit.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +commit_sha+ - The reset HEAD to this commit SHA.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_reset_hard(master, 'ff81c01c5', '~/git_repo')
def git_reset_hard(host, commit_sha, git_repo_path)
  git_on(host, "reset --hard #{commit_sha}", git_repo_path)
end

# Revert the Puppet environments back to a pristine 'production' branch while deleting all other branches.
#
# ==== Attributes
#
# * +host+ - One or more hosts to act upon, or a role (String or Symbol) that identifies one or more hosts.
# * +commit_sha+ - The reset 'production' branch HEAD to this commit SHA.
# * +git_repo_path+ - The path to the git repository on the target host.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# git_revert_environment(master, 'ff81c01c5', '~/git_repo')
def git_revert_environment(host, commit_sha, git_repo_path)
  #Reset 'production' branch to know clean state.
  git_on(host, 'checkout production', git_repo_path)
  git_reset_hard(host, commit_sha, git_repo_path)

  #Get all branches except for 'production'.
  local_branches = git_on(host, 'branch | grep -v "production" | xargs', git_repo_path).stdout()

  #Delete all other branches except for 'production' locally and remotely.
  if local_branches != "\n"
    git_on(host, "branch -D #{local_branches}", git_repo_path)
  end

  #Force push changes to remote.
  git_on(host, 'push origin --mirror --force', git_repo_path)
  git_on(host, 'push origin --mirror --force', git_repo_path)
end
