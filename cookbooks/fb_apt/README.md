fb_apt Cookbook
====================
The `fb_apt` cookbook installs and configures APT, the Debian package
management tool.

Requirements
------------

Attributes
----------
* node['fb_apt']['config']
* node['fb_apt']['distro']
* node['fb_apt']['keys']
* node['fb_apt']['keyserver']
* node['fb_apt']['mirror']
* node['fb_apt']['preserve_sources_list_d']
* node['fb_apt']['preferences']
* node['fb_apt']['repos']
* node['fb_apt']['update_delay']
* node['fb_apt']['want_backports']
* node['fb_apt']['want_non_free']
* node['fb_apt']['want_source']
* node['fb_apt']['preserve_unknown_keyrings']
* node['fb_apt']['allow_modified_pkg_keyrings']

Usage
-----
To install and configure APT include `fb_apt`, which will populate the
repository sources in `/etc/apt/sources.list` and update the package cache
during the run if it's older than `node['fb_apt']['update_delay']` seconds
(defaults to 86400). To force an update on every Chef run, set this attribute
to 0. The actual update is done via the `execute[apt-get update]` resource,
which other cookbooks can suscribe to or notify as well.

### Repository sources
By default the cookbook will setup the base distribution repos based on the
codename (as defined in `node['lsb']['codename']`) using a sensible default
mirror for the package sources. The mirror can be customized with
`node['fb_apt']['mirror']`; if set to `nil`, base repos will not be included
at all in `/etc/apt/sources.list`. If base repos are enabled, the additional
`backports` and `non-free` sources can be enabled with the
`node['fb_apt']['want_backports']` and `node['fb_apt']['want_non_free']`
attributes, and source code repos can be enabled with
`node['fb_apt']['want_source']`; these all default to `false`.

Additional repository sources can be added with `node['fb_apt']['repos']`. By
default `fb_apt` will clobber existing contents in `/etc/apt/sources.list.d` to
ensure it has full control on the repository list; this can be disabled with
`node['fb_apt']['preserve_sources_list_d']`.

### Keys
They `keys` hash is pre-populated with any keys from pkg-owned keyrings that
exist in `/etc/apt/trusted.gpg.d/` so you don't need to worry about keeping
a list of repository keys in sync.

You can add to this, but setting a key of your keyid and a value of either `nil`
or the PEM-encoded key. If `key` is `nil` the key will be automatically fetched
from the `node['fb_apt']['keyserver']` keyserver (`keys.gnupg.net` by default).
Example:

```
node.default['fb_apt']['keys']['94558F59'] = nil
node.default['fb_apt']['keys']['F3EFDBD9'] = <<-eos
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
eos
```

Automatic key fetching can be disabled by setting the keyserver to `nil`; this
will produce an exception for any unspecified key.

By default any keyring in `/etc/apt/trusted.gpg.d` that is not owned by a
package will be deleted unless you set `preserve_unknown_keyrings` to false.

If a keyring owned by a package is found to have been modified (based on
`dpkg -V`), then the run will fail, unless `allow_modified_pkg_keyrings` is
set.

### Configuration
APT behaviour can be customized using `node['fb_apt']['config']`, which will be
used to populate `/etc/apt/apt.conf`. Note that this will take precedence over
anything in `/etc/apt/apt.conf.d`. Example:

```
node.default['fb_apt']['config']['Acquire::http'].merge!({
  'Proxy' => 'http://myproxy:3412',
})
```

### Preferences
You can fine tune which versions of packages will be selected for installation
by tweaking APT preferences via `node['fb_apt']['preferences']`. Note that we
clobber the contents of `/etc/apt/preferences.d` to ensure this always takes
precedence. Example:

```
node.default['fb_apt']['preferences'][
  'Pin dpatch package from experimental'].merge!({
    'Package' => 'dpatch',
    'Pin' => 'release o=Debian,a=experimental',
    'Pin-Priority' => 450,
  })
```

### Distro
As mentioned above, `fb_apt` can assemble the basic sources for you. It uses
the LSB "codename" of the current systemd to build the URLs. In the event you
want to use Chef to upgrade across distros, however, you can set
`node['fb_apt']['distro']` to the appropriate name and it will be used instead.
