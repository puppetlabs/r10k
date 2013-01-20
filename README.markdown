r10k
====

Opinionated and semi-intelligent deployment of Puppet manifests and modules.

Description
-----------

[workflow]: http://puppetlabs.com/blog/git-workflow-and-puppet-environments/
[librarian]: https://github.com/rodjek/librarian-puppet

r10k is an intelligent implementation of the [dynamic puppet environment
workflow][workflow]. It aggressively caches and tries to minimize network
activity to ensure that interactive deployment is as fast as possible. It
supports the [librarian-puppet Puppetfile format][librarian] for installing
multiple independent Puppet modules.

Assumptions
-----------

To make r10k as responsive as possible, it makes a number of assumptions.

### Puppet modules are stored in git

Yep.

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

### Via git

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

### Via the forge

Puppet modules can be installed from the forge using the Puppet module tool.

    # This is currently a noop but will be supported in the future.
    forge 'forge.puppetlabs.com'

    # Install puppetlabs-stdlib from the Forge
    mod 'puppetlabs/stdlib', '2.5.1'
