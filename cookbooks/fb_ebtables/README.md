fb_ebtables Cookbook
====================
Basic cookbook to manage ebtables.

Requirements
------------

Attributes
----------
* node['fb_ebtables']['enable']
* node['fb_ebtables']['manage_packages']
* node['fb_ebtables']['sysconfig'][$KEY]

Usage
-----
Include `fb_ebtables` to manage ebtables on a machine. By default, the cookbook
will manage the ebtables packages; this can be opted out of by setting
`node['fb_ebtables']['manage_packages']`. The ebtables service itself is
disabled by default; to enable it set `node['fb_ebtables']['enable']` to true.

### Sysconfig
The `/etc/sysconfig/ebtables-config` config file can be configured using 
`node['fb_ebtables']['sysconfig']`. This hash will be translated to key-value 
pairs in the config file. The keys will automatically be upper-cased and 
prefixed with `EBTABLES_` as necessary. For example:

```
node.default['fb_ebtables']['sysconfig']['modules'] = 'nat'
```

would translate to:

```
EBTABLES_MODULES="nat"
```

### Unsupported features
This cookbook does not manage the ebtables ruleset.
