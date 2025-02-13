fb_spamassassin Cookbook
========================

Requirements
------------

Attributes
----------
* node['fb_spamassassin']['local']
* node['fb_spamassassin']['spamd_sysconfig']
* node['fb_spamassassin']['sa_sysconfig']
* node['fb_spamassassin']['preserve_os_pre_files']
* node['fb_spamassassin']['plugins']
* node['fb_spamassassin']['enable_compat']
* node['fb_spamassassin']['enable_update_job']

Usage
-----
### Daemon configuration

The `local` hash is a ruby-hash reprsentation of the `local.cf` configuration
file for SpamAssassin. It follows the key=val format of SpamAssassin configs
with one exception: conditionals. In order to ensure that configuration items
within conditionals are kept within the appropriate conditional, those should
be created as sub-hash:

```ruby
node.default['fb_spamassassin']['local'][
    'ifplugin Mail::SpamAssassin::Plugin::Shortcircuit'] = {
  'shortcircuit USER_IN_WHITELIST' => 'on',
}
```

Will render in the configuration file as:

```text
ifplugin Mail::SpamAssassin::Plugin::Shortcircuit
  shortcircuit USER_IN_WHITELIST on
endif
```

For items that can be multiply defined, let the value be an array. For example:

```ruby
node.default['fb_spamassassin']['local']['bayes_ignore_header'] = [
  'X-Bogosity'
  'X-Spam-Flag',
  'X-Spam-Status',
  'X-Spam-Checker-Version',
]
```

Will render as:

```text
bayes_ignore_header X-Bogosity
bayes_ignore_header X-Spam-Flag
bayes_ignore_header X-Spam-Status
bayes_ignore_header X-Spam-Checker-Version
```

Note: the above is part of the default config of this cookbook.

### Sysconfig

The variables that the spamd init or unit files parse are controlled by
`node['fb_spamassassin']['spamd_sysconfig']`, which will be the appropriate
files for your OS. Casing will automatically be up-cased, so you can use
lowercase:

```ruby
node.default['fb_spamassassin']['spamd_sysconfig']['options'] = '....'
```

Likewise, the variables that the update job reads can be populated with

```ruby
node.default['fb_spamassassin']['sa_sysconfig']['options'] = '....'
```

### Plugin loading (aka. preloading)

Any plugins in the hash `node['fb_spamassassin']['plugins']` will be loaded
via `init.pre`. Note that the value here is ignored and thus should be set
to `nil`. It is a hash simply to make it easier to work with across a Chef run.

By default this cookbook will preserve the OS plugin loading files that most
OS packages drop off in the form of `vXXX.pre` (e.g. `v310.pre`), so you only
need to specify additional packages. If you would like to control all plugin
loading, set `node.default['fb_spamassassin']['preserve_os_pre_files'] = false`
and this cookbook will remove those files.

### Compatibility Flags

This cookbook will look through the hash in
`node['fb_spamassassin']['enable_compat']`, and any that are set to true will
be enabled in `init.pre`. By default `welcomelist_blocklist` is set to true.

### Automatic Rule Updates

This cookbook enables the periodic update job (systemd timer) to refresh SA
rules. To disable them set
`node.default['fb_spamassassin']['enable_update_job'] = false`.

Note that this variable will overwrite the appropriate variable in the
`node['fb_spamassassin']['sa_sysconfig']` hash at the last moment, so you do
not need to worry about setting.

### spamd

While the service unit name for spamd is different on different platforms, we
name the resource `service[spamd]` so that if you would like to notify from or
subscribe to it, you it is simple to do so.
