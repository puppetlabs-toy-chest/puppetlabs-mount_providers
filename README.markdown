Mount Providers
===============

This module is designed to provide additional functionality and support the
native mount type inside of Puppet.  The module provides two additional
resource types not provided by Puppet core:

  * mountpoint
  * mounttab

Please see the output of `puppet describe mountpoint` and `puppet describe
mounttab` for more information about the types and providers supplied by this
module.

Installation
============

This module is installable from the Puppet Forge using the `puppet module` command.

    $ puppet module install puppetlabs-mount_providers

Source
======

 * [mount\_providers](https://github.com/puppetlabs/puppetlabs-mount_providers)

Known Issues
============

This module will cause `puppet describe` to throw an error on Puppet versions
between 2.6.8 and 2.6.14.  The error is:

    root@ubuntu-10:/etc/puppetlabs/puppet/modules# puppet describe mounttab
    Could not run: Could not autoload /etc/puppetlabs/puppet/modules/puppetlabs-mount-providers/lib/puppet/type/mountpoint.rb:undefined method 'downcase' for nil:NilClass

Puppet has been patched to fix this bug.  Please see [Issue
13070](http://projects.puppetlabs.com/issues/13070) for details about when this
fix has been released.
