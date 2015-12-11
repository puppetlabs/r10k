Updating Your Puppetfile
========================

Over time, your Puppetfile may become stale and reference older versions of modules or miss dependencies for the modules. Your Puppetfile will require maintenance to keep it up to date.

Manual Updates
--------------

You can manually update your Puppetfile very easily. By visiting the module's homepage on the [Puppet Forge](https://forge.puppetlabs.com/), you can determine the new version of a module and update it:

    # Original
    mod 'puppetlabs/apache', '0.10.0'
    
    # New
    mod 'puppetlabs/apache', '1.0.0'

When using a module directly from a git/svn repo, the `:tag` or `:ref` should be updated:

    # Original
    mod 'apache',
      :git => 'https://github.com/puppetlabs/puppetlabs-apache',
      :tag => '0.10.0'
      
    # Original
    mod 'apache',
      :git => 'https://github.com/puppetlabs/puppetlabs-apache',
      :tag => '1.0.0'

Dependency tracking can be done on the Puppet Forge as well by looking at the Dependency tab (Ex: [puppetlabs/apache](https://forge.puppetlabs.com/puppetlabs/apache/dependencies) and visiting each module in turn, or examining `metadata.json` in non-forge modules.

Automatic Updates
-----------------

The manual update process is sufficient when updating a small number of modules for a specific effort. Automatic tooling is helpful when updating a lengthier number of modules and for scheduled updates. A number of tools have been provided by the Puppet user community to assist with this. You are encouraged to review each tool before using them, and use of these tools is at your own risk.

* [ra10ke](https://rubygems.org/gems/ra10ke) ([project page](https://github.com/tampakrap/ra10ke/)) - A set of rake tasks to scan the Puppetfile for out of date modules
* [puppetfile-updater](https://rubygems.org/gems/puppetfile-updater/) ([project page](https://github.com/camptocamp/puppetfile-updater)) - A set of rake tasks to scan the Puppetfile, find newer versions, update the Puppetfile, and commit the changes.
* [generate-puppetfile](https://rubygems.org/gems/generate-puppetfile) ([project page](https://github.com/rnelson0/puppet-generate-puppetfile)) - A command line tool to generate raw Puppetfiles, update existing Puppetfiles, and optionally generate a `.fixtures.yml` file.
