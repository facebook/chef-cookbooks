fb_sasl Cookbook
================

Requirements
------------

Attributes
----------
* node['fb_sasl']['enable_saslauthd']
* node['fb_sasl']['manage_packages']
* node['fb_sasl']['modules']
* node['fb_sasl']['sysconfig']

Usage
-----

### Packages

By default, this cookbook will install relevant SASL packages. To disable this,
set `node['fb_sasl']['enable_saslauthd']` to `false`.

By default this cookbook installs on the basic SASL package for your distro. If
you need additional modules, you can add them to `node['fb_sasl']['modules']`
and the additional packages will be installed. Note that this configuration is
used to build the package name, so it may be distribution dependent. Here's an
example:

```ruby
node.default['fb_sasl']['modules'] << 'ldap'
```

This will add `libsasl2-modules-ldap` to the list of packages to install on
Debian-like distros while on Fedora-like distros it'll add `cyrus-sasl-ldap`.

### saslauthd

Most simple configurations do not require running `saslauthd`, and as such, the
default in this cookbook is to disable it. You can enable it by setting
`node['fb_sasl']['enable_saslauthd']` to `true`.

Note that while Debian-like distros have support for running multiple
instances, this cookbook does not support such a configuration. Only the
default single-instance is supported by this cookbook.

### sysconfig

`saslauthd` does not have a configuration file and it's configuration is
specified by options passed to it, and those options are controlled in the
sysconfig file.

You can specify the various configs via `node['fb_sasl']['sysconfig']`, but you
should check the documentation for your distro, as they options are different,
for example, `mech` vs. `mechanism`. We have provided appropriate defaults that
are valid for each distro.

There are two important things to remember about setting `sysconfig`:

* Use **lowercase** for the keys. We will upcase them when we generate the
  file, but using all lowercase ensures no conflicts.
* Do **not** specify `start` (for those of you on Debian-like distros). We
  will set this based on `node['fb_sasl']['enable_saslauthd']`.
