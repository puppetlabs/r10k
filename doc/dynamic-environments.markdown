Dynamic Environments
====================

r10k implements the dynamic environment workflow with Puppet. This allows you to
create, modify, and remove Puppet environments on the fly with Git branches.

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

Configuration
-------------

r10k uses a configuration file to determine how dynamic environments should be
deployed.

### Config file location

By default r10k will try to read `/etc/r10k.yaml` for configuration settings.
You can specify an alternate configuration file by specifying the `--config`
option, like so:

    r10k deploy -c /srv/puppet/r10k.yaml

### Configuration format

#### cachedir

The `cachedir` setting specifies where r10k should keep cached information.
Right now this is predominantly used for caching git repositories but will be
expanded as other subsystems can take advantage of caching.

For example:

    ---
    # Store all cache information in /var/cache
    cachedir: '/var/cache/r10k'

#### sources

The `sources` setting specifies what repositories should be used for creating
dynamic environments.

The `sources` setting is a hash where each key is the short name of a specific
repository (for instance, "qa" or "web" or "ops") and the value is a hash of
properties for that source.

#### source sub-options

##### remote

The remote is the URL of the Git repository to clone. This repository will need
to be cloned without user intervention so SSH keys will need to be configured
for the user running r10k.

##### basedir

The basedir is the directory that will be populated with Puppet environments.
This directory will be entirely managed by r10k and any contents that r10k did
not put there will be _removed_.

##### prefix

The prefix setting allows environment names to be prefixed with the short name
of the given source. This prevents collisions when multiple sources are deployed
into the same directory.

#### source examples

##### Basic examples

The majority of users will only have a single repository where all modules and
hiera data files are kept. In this case you will specify a single source:

    ---
    # Specify a single environment source
    sources:
      operations:
        remote: 'git@github.com:my-org/org-modules'
        basedir: '/etc/puppet/environments'

- - -

##### Advanced examples

For more complex cases where you want to store hiera data in a different
repository and your modules in another repository, you can specify two sources:

    ---
    sources:
      operations:
        remote: 'git@github.com:my-org/org-modules'
        basedir: '/etc/puppet/environments'
      hiera:
        remote: 'git@github.com:my-org/org-hiera-data'
        basedir: '/etc/puppet/hiera-data'

- - -

Alternately you may want to create separate environments from multiple
repositories. This is useful when you want two groups to be able to deploy
Puppet modules but they should only have write access to their own modules and
not the modules of other groups.

    ---
    sources:
      main:
        remote: 'git@github.com:my-org/main-modules'
        basedir: '/etc/puppet/environments'
        prefix: false # Prefix defaults to false so this is only here for clarity
      qa:
        remote: 'git@github.com:my-org/qa-puppet-modules'
        basedir: '/etc/puppet/environments'
        prefix: true
      dev:
        remote: 'git@github.com:my-org/dev-puppet-modules'
        basedir: '/etc/puppet/environments'
        prefix: true

This will create the following directory structure:


    /etc/puppet/environments
    |-- production       # main-modules repository, production branch
    |-- upgrade_apache   # main-modules repository, upgrade_apache branch
    |-- qa_production    # qa repository, production branch
    |-- qa_jenkins_test  # qa repository, jenkins_test branch
    |-- dev_production   # dev repository, production branch
    `-- dev_loadtest     # dev repository, loadtest branch

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
