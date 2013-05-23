r10k
====

Opinionated and semi-intelligent Git based deployment of Puppet manifests and modules.

Description
-----------

[workflow]: http://puppetlabs.com/blog/git-workflow-and-puppet-environments/
[librarian]: https://github.com/rodjek/librarian-puppet

r10k is an intelligent implementation of the [dynamic puppet environment
workflow][workflow]. It aggressively caches and tries to minimize network
activity to ensure that interactive deployment is as fast as possible. It
supports the [librarian-puppet Puppetfile format][librarian] for installing
multiple independent Puppet modules.

- - -

r10k is designed to deploy branches of a Git repository as environments and can
optionally deploy modules specific in a Puppetfile.

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

Puppetfile support
------------------

r10k implements the [librarian-puppet][librarian] Puppetfile format. r10k will
create and manage the `modules` directory within your Git repository. It's
recommended that you add `/modules` to your project .gitignore.

A deployed environment with a Puppetfile will look something like this:

    .
    ├── Puppetfile   # An optional Puppetfile
    ├── dist         # Internally developed generic modules
    ├── modules      # Puppet modules deployed by r10k
    └── site         # Modules for deploying custom services

It is also possible to set an alternate name/location for your `Puppetfile` and 
`modules` directory. This is usefull if you want to control multiple environments 
and have a single location for your `Puppetfile`.

Example:

    PUPPETFILE=/etc/r10k.d/Puppetfile.production \
    PUPPETFILE_DIR=/etc/puppet/modules/production \
    /usr/bin/r10k puppetfile install

### Installing modules from git

Puppet modules can be installed from any valid git repository.


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

Configuration
-------------

r10k will look in /etc/r10k.yaml for its config file by default.

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

This basic configuration should be enough for most deployment needs.

Contributors
------------

  - Justen Walker (https://github.com/justenwalker)
  - John-John Tedro (https://github.com/udoprog)
  - Lars Tobias Skjong-Børsting (https://github.com/larstobi)
