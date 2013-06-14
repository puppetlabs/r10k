r10k
====

Puppet environment and module deployment

Description
-----------

[librarian-puppet]: https://github.com/rodjek/librarian-puppet
[workflow]: http://puppetlabs.com/blog/git-workflow-and-puppet-environments/

r10k provides a general purpose toolset for deploying Puppet environments and
modules. It implements the [Puppetfile][librarian-puppet] format and provides a native
implementation of Puppet [dynamic environments][workflow].

Installation
------------

r10k should be compatible with Ruby 1.8.7, 1.9.3, and 2.0.0. Any issue with
those versions should be considered a bug.

### Rubygems

For general use, you should install r10k from Ruby gems:

    gem install r10k
    r10k --help

### Bundler

If you have more specific needs or plan on modifying r10k you can run it out of
a git repository using Bundler for dependencies:

    git clone git://github.com/adrienthebo/r10k
    cd r10k
    bundle install
    bundle exec r10k --help

### Puppet Enterprise

Puppet Enterprise uses its own Ruby, so you need to use the correct version of gem when installing r10k.

    /opt/puppet/bin/gem install r10k
    r10k --help

Common Commands
---------------

### Deploy all environments and Puppetfile specified modules

    r10k deploy environment -p

### Deploy all environments but don't update/install modules

    r10k deploy environment

### Deploy a specific environment, and its Puppetfile specified modules

    r10k deploy environment your_env -p

### Deploy a specific environment, but not its modules

    r10k deploy environment your_env

### Display all environments being managed by r10k

    r10k deploy display

### Display all environment being managed by r10k, and their modules.

    r10k deploy display -p

Puppetfile support
------------------

r10k can operate on a Puppetfile as a drop-in replacement for librarian-puppet.
Puppetfiles are a simple Ruby based DSL that specifies a list of modules to
install, what version to install, and where to fetch them from.

Puppetfile based commands are under the `r10k puppetfile` subcommand.

### Installing modules from git

Puppet modules can be installed from any valid git repository:

    mod 'rsyslog', :git => 'git://github.com/puppetlabs-operations/puppet-rsyslog.git'

You can deploy a module from a specific branch, tag, or git ref. By default r10k
will track `master` and will assume that you want to keep the module up to date.
If you want to track a specific branch, then

Examples:

    # track master
    mod 'filemapper',
      :git => 'git://github.com/adrienthebo/puppet-filemapper.git'

    # Install the filemapper module and track the 1.1.x branch
    mod 'filemapper',
      :git => 'git://github.com/adrienthebo/puppet-filemapper.git',
      :ref => '1.1.x'

    # Install filemapper and use the 1.1.1 tag
    mod 'filemapper',
      :git => 'git://github.com/adrienthebo/puppet-filemapper.git',
      :ref => '1.1.1'

    # Install filemapper and use a specific git commit
    mod 'filemapper',
      :git => 'git://github.com/adrienthebo/puppet-filemapper.git',
      :ref => 'ec2a06d287f744e324cca4e4c8dd65c38bc996e2'

### Installing modules from the Puppet forge

Puppet modules can be installed from the forge using the Puppet module tool.

    # This is currently a noop but will be supported in the future.
    forge 'forge.puppetlabs.com'

    # Install puppetlabs-stdlib from the Forge
    mod 'puppetlabs/stdlib', '2.5.1'

Basic Environment Structure
---------------------------

r10k supports Dynamic Environments (see below), but simple environment structures
are also supported.

The basic structure of an environments that uses a Puppetfile to install modules is

    .
    |-- manifests
      |-- site.pp
    |-- Puppetfile
    |-- .gitignore

site.pp would contain your node definitions, and the Puppetfile would specify the modules
to be installed.  r10k automatically creates the 'modules' directory when it applies the
Puppetfile.

It's important to put the modules directory in .gitignore so that git doesnt' accidentally 
put it into the repo.

    modules/

Dynamic environment support
---------------------------

r10k implements the dynamic environment workflow. Given a git repository with
multiple branches R10k can create an environment for each branch. This means
that you can use git with the normal branch-develop-merge workflow, and easily
test your changes as you work.

Deployment commands are implemented under the `r10k deploy` subcommand.

### Git repository layout

[modulepath]: http://docs.puppetlabs.com/references/stable/configuration.html#modulepath

r10k makes the assumption that Puppet modules are stored in subdirectories of
the Git repository. These directories are all loaded into the Puppet master with
the [modulepath][modulepath] directive.

For example, your Git repository would have a structure something like this:

    .
    ├── Puppetfile   # An optional Puppetfile
    ├── dist         # Internally developed generic modules
    └── site         # Modules for deploying custom services


### Using dynamic environments with a Puppetfile


r10k can implement a hybrid workflow with dynamic environments and Puppetfiles.
If a Puppetfile is available at the root of a deployed environment, r10k can
create and manage the `modules` directory within your Git repository.

It's recommended that you add `/modules` to your project .gitignore.

A deployed environment with a Puppetfile will look something like this:

    .
    ├── Puppetfile   # An optional Puppetfile
    ├── dist         # Internally developed generic modules
    ├── modules      # Puppet modules deployed by r10k
    └── site         # Modules for deploying custom services

It is also possible to set an alternate name/location for your `Puppetfile` and
`modules` directory. This is useful if you want to control multiple environments
and have a single location for your `Puppetfile`.

Example:

    PUPPETFILE=/etc/r10k.d/Puppetfile.production \
    PUPPETFILE_DIR=/etc/puppet/modules/production \
    /usr/bin/r10k puppetfile install

### Dynamic environment configuration

r10k uses a yaml based configuration file when handling deployments. The default
location is in /etc/r10k.yaml and can be specified on the command line.

### Example

    # The location to use for storing cached Git repos
    :cachedir: '/var/cache/r10k'

    # A list of git repositories to create
    :sources:
      # This will clone the git repository and instantiate an environment per
      # branch in /etc/puppet/environments
      :plops:
        remote: 'git@github.com:my-org/org-shared-modules'
        basedir: '/etc/puppet/environments'

    # This directory will be purged of any directory that doesn't map to a
    # git branch
    :purgedirs:
      - '/etc/puppet/environments'


Multiple git repositories can be specified, which is handy if environments are broken up by application.
Application 1 could have its own environment repository with app1_dev, app1_tst, and app1_prd branches while 
Application 2 could have its own environment repository with app2_dev, app2_tst, app2_prd branches.

You might want to take this approach if your environments vary greatly.  If you often find yourself making
changes to your Application 1 environments that don't belong in your Application 2 environments, merging changes
can become difficult if all of your environment branches are in a single repository.

This approach also makes security easier as teams can be given access to control their application's environments 
without being able to accidentally impact other groups.

### Multiple Environment Repositories Example

    # The location to use for storing cached Git repos
    :cachedir: '/var/cache/r10k'

    # A list of git repositories to create
    :sources:
      # This will clone the git repository and instantiate an environment per
      # branch in /etc/puppet/environments
      :app1:
        remote: 'git@github.com:my-org/app1-environments'
        basedir: '/etc/puppet/environments'
      :app2:
        remote: 'git@github.com:my-org/app2-environments'
        basedir: '/etc/puppet/environments'

    # This directory will be purged of any directory that doesn't map to a
    # git branch
    :purgedirs:
      - '/etc/puppet/environments'



More information
----------------

The original impetus for r10k is explained at http://somethingsinistral.net/blog/rethinking-puppet-deployment/

Contributors
------------

  - Justen Walker (https://github.com/justenwalker)
  - John-John Tedro (https://github.com/udoprog)
  - Lars Tobias Skjong-Børsting (https://github.com/larstobi)
  - Chuck (https://github.com/csschwe)
  - Greg Baker (https://github.com/Ancillas)
