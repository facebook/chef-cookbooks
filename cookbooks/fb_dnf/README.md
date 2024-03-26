fb_dnf Cookbook
===============

Requirements
------------

Attributes
----------
* node['fb_dnf']['config'][$SECTION][$KEY][$VALUE]
* node['fb_dnf']['disable_makecache_timer']
* node['fb_dnf']['manage_packages']
* node['fb_dnf']['modules'][$MODULE][$CONFIG]
* node['fb_dnf']['repos'][$GROUP]['repos'][$REPO][$KEY][$VALUE]

Usage
-----
This cookbook manages the DNF package manager and its configuration. It does
not manage repo definitions in `/etc/yum.repos.d`, which are separately managed
by `fb_yum_repos`.

### FB::Dnf
The following methods are available:

* `FB::Dnf.gen_module_yaml(module_name, module_data)`
  Takes a module name and data and generates the appropriate YAML configuration
  for a module override.

### Packages
By default, `fb_dnf` will manage the packages for the DNF stack on the system;
this can be disabled by setting `node['fb_dnf']['manage_packages']` to `false`.

### Configuration
Global DNF configuration can be managed via `node['fb_dnf']['config']`. By
default, `fb_dnf` will set a configuration that matches the running distro
stock setup. Example:

```ruby
node.default['fb_dnf']['config']['main']['gpgcheck'] = false
```

Repository definitions can each specify their own configuration settings which
will take precendece over the global ones. Repositories can be defined in two
ways:

* via `node['fb_dnf']['repos']`, which will add them to `/etc/dnf/dnf.conf`
  alonside the global configuration settings
* via `node['fb_yum_repos']['repos']`, which will add them as repo files under
  `/etc/yum.repos.d`

These are not mutually exclusive and can be mixed as desired. See the README
for `fb_yum_repos` for details on how to define repositories.

### Disable dnf-makecache.timer

The dnf RPM includes a default make cache timer. This is not always required
depending how one wants to use dnf. Set
`node['fb_dnf']['disable_makecache_timer']` API to `true` to stop this periodic
refresh of the dnf metadata cache.

To rollback / renable *dnf-makecahce.timer* you also need a second API boolean set:
- `node['fb_dnf']['enable_makecache_timer']` (set to `true`)
This is to protect use cases where *dnf-mcachecache.timer* is being disabled/stopped
another way.

### Modularity support
DNF supports modules which may need to be enabled, disabled, or default. You
can use `node['fb_dnf']['modules']` to configure modules. Do this via:

```ruby
node.default['fb_dnf']['modules']['mysql'] = {
  'stream' => 'facebook',
}
```

If you simply want to disable a module, make this an empty hash:

```ruby
node.default['fb_dnf']['modules']['mysql'] = {}
```

You can also use this API to explicitly enable a module, for example:

```ruby
node.default['fb_dnf']['modules']['nodejs'] = {
  'enable' => true,
  'stream' => 13,
}
```
