fb_yum_repos Cookbook
=====================

Requirements
------------

Attributes
----------
* node['fb_yum_repos']['manage_repos']
* node['fb_yum_repos']['preserve_unknown_repos']
* node['fb_yum_repos']['repos'][$GROUP]['repos'][$REPO][$KEY][$VALUE]

Usage
-----
This cookbooks manages the Yum repository definitions in `/etc/yum.repos.d` on
systems running the Yum or DNF package managers. It does not manage the package
manager itself, but it provides the building blocks for other cookbooks to do
so.

### FB::YumRepos
The following methods are available:

* `FB::YumRepos.get_default_gpg_key(node)`
  Takes the node in and returns the distribution-appropriate default GPG key
  URI for the running system.

* `FB::YumRepos.gen_config_value(key, value)`
  Given a `key` and a `value` for a Yum config file, return the appropriate
  String representation for the `value`. Notably, this method is aware of the
  different conventions used for booleans and will try to return the most
  appropriate result for the given key.

* `FB::YumRepos.gen_repo_config(node, name, config)`
  Takes in the node, a repo name and a basic config Hash, and returns a fully
  populated config Hash suitable that completely specifies a repo configuration
  for the running system.

* `FB::YumRepos.gen_repo_entry(node, name, config)`
  Similar to `FB::YumRepos.gen_repo_config` and building onto it, generate a
  repo entry String suitable for rendering into a template from a partial repo
  configuration.

### Resources
The following resources are available:

* `execute[clean yum metadata]` will flush the package manager metadata,
  causing them to be refreshed on the next operation

* `whyrun_safe_ruby_block[clean chef yum metadata]` will flush the Chef cache
  used to track the state of the package manager

* `fb_yum_repos_config` will render a Yum-style configuration file; this could
  be used, for example, to generate `/etc/yum.conf` or `/etc/dnf/dnf.conf` in
  another cookbook.

### Repositories management
By default `fb_yum_repos` will manage the Yum repositories in
`/etc/yum.repos.d` based on the contents on `node['fb_yum_repos']['repos']`. If
this isn't desired, set `node['fb_yum_repos']['manage_repos']` to `false`.

Repositories are bucketed into repo groups, and each group will map to a
`.repo` file under `/etc/yum.repos.d`. By default, `fb_yum_repos` will delete
files that do not match any group defined in Chef; this can be disabled by
setting `node['fb_yum_repos']['preserve_unknown_repos']` to `true`.

Repositories for each group are defined as hashes under the
`node['fb_yum_repos']['repos'][$GROUP]['repos']` attribute; only essential
fields have to be specified, `fb_yum_repos` will populate the rest with
sensible defaults as needed. For example:

```ruby
node.default['fb_yum_repos']['repos']['foo'] = {
  'description' => 'Repos for foo'
  'repos' => {
    'foo' => {
      'name' => 'foo packages',
      'baseurl'  => 'https://my.repo.server/repos/foo',
      'gpgcheck' => false,
    },
    'bar' => {
      'baseurl' => 'https://my.repo.server/repos/bar',
      'enabled' => false,
      'gpgkey'  => 'https://my.repo.server/keys/bar-gpg-key',
    },
  },
}
```

will result in `/etc/yum.repos.d/foo.repo` being created with:

```
# Repos for foo
[foo]
name=foo packages
baseurl=https://my.repo.server/repos/foo
gpgcheck=0
enabled=1

[bar]
name=bar
baseurl=https://my.repo.server/repos/bar
gpgcheck=1
enabled=0
gpgkey=https://my.repo.server/keys/bar-gpg-key
```
