fb_sssd Cookbook
================
Manage sssd configuration

Requirements
------------

Attributes
----------
* node['fb_sssd']['enable']
* node['fb_sssd']['manage_packages']
* node['fb_sssd']['config']

Usage
-----
### enable

Enable will install, setup, and start sssd if `true`, and will stop and
uninstall it if `false` (default).

### manage_packages

If true (default) will install or uninstall packages based on `enable`. Otherwise does not touch packages.

### config

The config is a two-level hash where the top-level hash is the **section** of the INI file (`/etc/sssd/sssd.conf`), and the hash under that is key-value pairs. For example:

```ruby
node.default['fb_sssd']['config']['nss']['default_shell'] = '/bin/bash'
```

is rendered as:

```text
[nss]
default_shell = /bin/bash
```

If the value is an array it is joined into a string using `, `, ala:

```ruby
node.default['fb_sssd']['config']['sssd']['services'] = [
  'nss',
  'pam',
  'ssh',
]
```

will be rendered as:

```text
[sssd]
services = nss, pam, ssh
```
