Git Based Dynamic Environments
==============================

r10k can use Git repositories to implement dynamic environments. You can create,
update, and delete Puppet environments automatically as part of your normal Git
workflow.

Dynamic Environments in a nutshell
----------------------------------

The core idea of dynamic environments is that you should be able to manage your
Puppet modules in the same manner that you would manage any other code base. It
builds on top of Git topic branch model.

[git-topic-branching]: http://git-scm.com/book/en/Git-Branching-Branching-Workflows#Topic-Branches "Git Topic Branches"

One of the most prevalent ways of using Git relies on using [topic branches][git-topic-branching].
Whenever changes need to be made that need to be reviewed or tested before going
live, they should be done in a different, short lived branch called a topic
branch. Work can be freely done on a topic branch in isolation and when the work
is completed it is merged into a "master" or "production" branch. This is very
powerful because it allows any number of people to rapidly develop features in
isolation and merge features in a single operation.

The dynamic environment model extends extends this git branching strategy to
your live Puppet masters. It creates a mapping between Git branches and Puppet
environments so that you can use the Git branching model and have that be
seamlessly reflected in Puppet environments. This means that creating a new Git
branch creates a new Puppet environment, updating a Git branch will update that
environment, and deleting a Git branch will remove that environment.

How it works
------------

r10k works by tracking the state of your git repositories and comparing them the
the currently deployed environments. If there's a Git branch that doesn't have a
corresponding Puppet environment then r10k will clone that branch into the
appropriate directory. When Git branches are updated r10k will update the
appropriate Puppet environment to the latest version. Finally if there are
Puppet environments that don't have matching Git branches, r10k will assume that
the branches for those environments were deleted and will remove those
environments.
