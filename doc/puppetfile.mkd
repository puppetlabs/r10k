Puppetfile
==========

The Puppetfile is a way to reuse independent Puppet modules in your codebase.

When directly working with Puppetfiles, you can use the `r10k puppetfile`
subcommand to interact with a Puppetfile.

When using r10k's deploy functionality, interacting with Puppetfiles is handled
on a case by case basis.

The Puppetfile format is actually implemented using a Ruby DSL so any valid Ruby
expression can be used. That being said, being a bit too creative in the DSL
can lead to surprising (read: bad) things happening, so consider keeping it
simple.

Module types
------------

### Git

Modules can be installed via git.

#### Examples

    # Install puppetlabs/apache and keep it up to date with 'master'
    mod 'apache',
      :git => 'https://github.com/puppetlabs/puppetlabs-apache'

    # Install puppetlabs/apache and track the 'docs_experiment' branch
    mod 'apache',
      :git => 'https://github.com/puppetlabs/puppetlabs-apache',
      :ref => 'docs_experiment'

You can also use the exact object type you want to check out. This may be a
little bit more work but it has the advantage that r10k make certain
optimizations based on the object type that you specify.

    mod 'apache',
      :git => 'https://github.com/puppetlabs/puppetlabs-apache',
      :tag => '0.9.0'

    mod 'apache',
      :git    => 'https://github.com/puppetlabs/puppetlabs-apache',
      :commit => '83401079053dca11d61945bd9beef9ecf7576cbf'

You can also explicitly specify a branch, but this behaves the same as
specifying :ref and is mainly useful for clarity.

    mod 'apache',
      :git    => 'https://github.com/puppetlabs/puppetlabs-apache',
      :branch => 'docs_experiment'

### Forge

Modules can be installed using the Puppet module tool.

If no version is specified the latest version available at the time will be
installed, and will be kept at that version.

    mod 'puppetlabs/apache'

If a version is specified then that version will be installed.

    mod 'puppetlabs/apache', '0.10.0'

If the version is set to :latest then the module will be always updated to the
latest version available.

    mod 'puppetlabs/apache', :latest

### SVN

Modules can be installed via SVN.

    mod 'apache',
      :svn => 'https://github.com/puppetlabs/puppetlabs-apache/trunk'

    mod 'apache',
      :svn => 'https://github.com/puppetlabs/puppetlabs-apache/trunk',
      :rev => '154'

Alternately,

    mod 'apache',
      :svn      => 'https://github.com/puppetlabs/puppetlabs-apache/trunk',
      :revision => '154'
