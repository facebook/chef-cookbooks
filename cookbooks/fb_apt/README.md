fb_apt Cookbook
====================
The `fb_apt` cookbook installs and configures APT, the Debian package
management tool.

Requirements
------------

Attributes
----------
* node['fb_apt']['allow_modified_pkg_keyrings']
* node['fb_apt']['apt_update_log_path']
* node['fb_apt']['config']
* node['fb_apt']['distro']
* node['fb_apt']['keymap']
* node['fb_apt']['keymap'][$NAME]
* node['fb_apt']['keys']
* node['fb_apt']['keyserver']
* node['fb_apt']['mirror']
* node['fb_apt']['preferences']
* node['fb_apt']['preserve_sources_list_d']
* node['fb_apt']['preserve_unknown_keyrings']
* node['fb_apt']['repos']
* node['fb_apt']['sources']
* node['fb_apt']['sources'][$NAME]
* node['fb_apt']['update_delay']
* node['fb_apt']['want_backports']
* node['fb_apt']['want_non_free']
* node['fb_apt']['want_source']

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
`node['fb_apt']['mirror']`; if set to `nil`, base repos will not be included at
all in `/etc/apt/sources.list`. If base repos are enabled, the additional
`backports` and `non-free` sources can be enabled with the
`node['fb_apt']['want_backports']` and `node['fb_apt']['want_non_free']`
attributes, and source code repos can be enabled with
`node['fb_apt']['want_source']`; these all default to `false`.

Additional repository sources can be added with `node['fb_apt']['sources']`
in this way:

```ruby
node.default['fb_apt']['sources']['cool_repo'] = {
  'url' => 'https://cool_repo.com/',
  'suite' => 'stable',
  'components' => ['main'],
  'key' => 'cool_repo', # this references keymap, see below
}
```

Entries in `sources` support the following keys:

* `type` - The type of repo, `deb` or `deb-src` - Optional, defaults to `deb`
* `url` - The URL of the repo
* `suite` - The suite to pull from - usually the OS version codename
* `components` - An array of components
* `options` - If present, must be a hash of options to put, such as `arch`
* `key` - A special-case option. This should be a string that maps to a key
  in `node['fb_apt']['keymap']`. The `options` hash will be updated with the
  `signed-by` value set to the appropriate path for the keyring generated.

By default `fb_apt` will clobber existing contents in `/etc/apt/sources.list.d`
to ensure it has full control on the repository list; this can be disabled with
`node['fb_apt']['preserve_sources_list_d']`.

*NOTE*: Older versions of this cookbook used `node['fb_apt']['repos']`. This
is deprecated. As of this writing, sources in this list will still be added
to the system, but a warning will be printed. The old syntax was significantly
lacking, didn't play well with keys, and was hard to modify.

### Keys

The `node['fb_apt']['keymap']` is designed to make it easy to work with the
per-repo keys that modern Apt requires. Simple associate a PEM value with a
name, and then use that name in any entries in `node['fb_apt']['sources']`
signed by that key. `fb_apt` will take the PEM, generate a keyring in
`/etc/apt/trusted.gpg.d/${NAME}.gpg` and populate the signed-by values in your
`sources.list`.

For example:

```ruby
node.default['fb_apt']['keymap']['cool'] = <<-eos
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
eos

node.default['fb_apt']['sources']['cool_app'] = {
  ...
  'key' => 'cool',
}
```

You can also make the keymap value a http/https URL, but if you do, the file will be
placed as-is in `trusted.gpg.d`, so it must be of the right format. Chef's
`remote_file` resource will be used to manage the file. This is intended for
repos who make full keyrings available instead of armored PEMs.

For example:

```ruby
node.default['fb_apt']['keymap']['cool'] = 'https://www.example.com/repo-key.gpg'
```

Anything in `/etc/apt/trusted.gpg.d` that is owned by a package or by this
cookbook will be kept, but any other file in there will be removed. Unless you
set `preserve_unknown_keyrings` to false.

If a keyring owned by a package is found to have been modified (based on
`dpkg -V`), then the run will fail, unless `allow_modified_pkg_keyrings` is
set.

*NOTE*: Older versions of this cookbook used `node['fb_apt']['keys']` which
attempted to pull keyid's from the internet and load them via the now-deprecated
`apt-key`. Use of that API will cause a warning, though this cookbook does still
support it for now. However, modern `apt-key` does nothing, so your config will
break if you do not migrate.

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

### Logging `apt-get update`

Set `node['fb_apt']['apt_update_log_path']` to log stdout and stderr of the
`apt-get update` command invoked by this cookbook. This may be useful for
debugging purposes. The caller must handle log rotation.
