fb_nsswitch Cookbook
====================
This cookbook configures `/etc/nsswitch.conf` and provides an API for modifying
all aspects of the `/etc/nsswitch.conf` file.

Requirements
------------

Attributes
----------
* node['fb_nsswitch']['databases']

Usage
-----
By default we set every database to use `files` as their source, except `hosts`
which will default to `files dns`. Database mappings can be set with the
`node['fb_nsswitch']['databases']`. attribute. Example:

    node.default['fb_nsswitch']['databases']['passwd'] = [
      'files',
      'ldap',
    ]
