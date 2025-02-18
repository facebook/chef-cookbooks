fb_ejabberd Cookbook
====================

Requirements
------------
Currently this only works on Debian/Ubuntu since ejabberd has not been packaged
for Fedora since F37.

Attributes
----------
* node['fb_ejabberd']['config']
* node['fb_ejabberd']['extra_packages']
* node['fb_ejabberd']['manage_packages']
* node['fb_ejabberd']['sysconfig']

Usage
-----
### Packages

This cookbook will install the ejabberd package for your platform along with
any extra packages specified in `extra_packages`. For example:

```ruby
node.default['fb_ejabberd']['extra_packages'] << 'ejabberd-mod-s2s-log'
```

If you prefer to manage packages yourself, set
`node['fb_ejabberd']['manage_packages']` to `false`.

### Configuration

The `ejabberd.yml` config is generated from `node['fb_ejabberd']['config']`. A
basic config is included in attributes, you can change it as you see fit. For
simple setups only `hosts` and `certfiles` should be needed.

### Service environment variables

The environment variables for the service are in
`node['fb_ejabberd']['sysconfig']`, use lowercase, the variables names will be
upcased when the file is generated. Note that `ejabberd_config_path` and
`contrib_modules_conf_dir` are hard-coded, per the FB standard of controlling
the config path, and thus will be ignored if set in this hash.
