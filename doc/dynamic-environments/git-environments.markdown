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

Dynamic environments and Puppetfiles
------------------------------------

TODO

Interacting with dynamic environments
-------------------------------------

r10k provides fairly fine grained controls over your environments to fit your
needs. If you want to do a full update of all of your environments and modules
and don't need it to be done in real time, you can trigger a full update and let
it run in the background. If you are actively developing code and need to run
very fast updates of one specific environment, you can do a targeted update of
that code as well.

All commands that deal with deploying environments are grouped under the `r10k
deploy` subcommand.

### Examples

#### Deploying environments

    # Update all environments across all sources. This can be slow depending
    # on the number of environments and modules that you're using.
    r10k deploy environment

    # Update a single environment. When you're actively working on an
    # environment this is the best way to deploy your changes.
    r10k deploy environment my_working_environment

    # This is the brute force approach of "update everything, ever." This can
    # run for an extremely long time so it should not be something you run
    # interactively on a regular basis.
    r10k deploy environment --puppetfile

#### Deploying modules

    # Update a single module across all environments This is useful for when
    # you're working on a module in an environment and only want to update that
    # one module.
    r10k deploy module apache

    # More than one module can be updated at a time.
    r10k deploy module apache jenkins java
