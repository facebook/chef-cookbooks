fb_kea Cookbook
===============

Requirements
------------

Attributes
----------
* node['fb_kea']['config']
* node['fb_kea']['config']['_common']
* node['fb_kea']['config']['control-agent']
* node['fb_kea']['config']['ddns']
* node['fb_kea']['config']['dhcp4']
* node['fb_kea']['config']['dhcp6']
* node['fb_kea']['enable_control-agent']
* node['fb_kea']['enable_ddns']
* node['fb_kea']['enable_dhcp4']
* node['fb_kea']['enable_dhcp6']
* node['fb_kea']['manage_packages']
* node['fb_kea']['verify_aa_workaround']

Usage
-----

### Packages

This cookbook will install all the relevant packages for you. If you do not
want this, set `node['fb_kea']['manage_packages']` to `false`.

### Configuration

This cookbook goes through a lot of effort to make configuration KEA and it's
various parts easier. This section will discuss the various shortcuts we've
enabled for you.

#### Common configs for dhcp4 and dhcp6

First - the configuration for the `kea-dhcp4` and `kea-dhcp6` are merged with
the `_common` config. So anything that you want to apply to both DHCP servers,
should be put into `node['fb_kea']['config']['_common']`, and anything specific
to one server or the other should be put directly into the respective hash.

The merge here is deep, so you can specify as little as possible. For example,
the common config has in it:

```ruby
{
  'control-socket' => {
    'socket-type' => 'unix',
  },
}
```

And the dhcp4 config has in it:

```ruby
{
  'control-socket' => {
    'socket-name' => '/run/kea4-ctrl-socket'',
  },
}
```

So you don't need to specify entirety of `control-socket` twice, just
additional values.

**NOTE**: The `ddns` and `control-agent` configs are **not** merged with the
`_common_` config, since they have much less in common.

#### Hash-to-array conversion

Second, in order to facilitate managing configuration throughout the run, parts
of the config that are normally an array should be specified as as hashes, but
with the key named "${key}-hash". This way it's easy for humans to reach into
any level of the config and change the right entry, but the configuration will
be converted properly upon rendering. For example:

```ruby
node.default['fb_kea']['dhcp4']['subnet4-hash']['wireless_clients'] = {
  'id' => 1,
  'subnet' => '10.0.0.0/24',
  'pools-hash' => {
    'wireless_pool1' => {
      'pool' => '10.0.0.2 - 10.0.0.99',
    },
    'wireless_pool2' => {
      'pool' => '10.0.0.100 - 10.0.0.254',
    },
  ...
}
```

This will get transformed to this in the config:

```json
{
  "subnet4": [
    {
      "id" => 1,
      "subnet" => "10.0.0.0/24",
      "pools": [
        {
          "pool": "10.0.0.2 - 10.0.0.99",
        },
        {
          "pool": "10.0.0.100 - 10.0.0.254",
        }
      ],
      ...
    }
  ]
}
```

Note here that `subnet4-hash => {}` was turned into `subnet4 => []`, and that
`pools-hash => {}` was turned into `pools => []`.

We have preseeded most of the top level ones for you in the default config, but
this can be done deeply at any level of the config and we recommend always
using these instead of the standard arrays.

This cookbook will check to ensure there isn't a conflict between a key and
it's auto-hash counterpart at the same level, and will fail the run if it
encounters this.

#### Control socket handling

When configuring control-agent, **you do not need to specify control-sockets**.

This part of the configuration will automatically be filled in for you based on
the configuration for the other services, taking into account merged common
configs where necessary.

It will only include sockets for the services you've marked as enabled,
ensuring a consistent configuration.

If you specify anything in
`node['fb_kea']['config']['control-agent']['control-sockets']`, it will be
overwritten and a warning will be printed.

Other than this, the configs work just like you'd expect.

### Enabling specific services

Each service can be enabled or disabled with the respective toggle,
`enable_dhcp4`, `enable_dhcp6`, and `enable_ddns`. When disabled the
configuration file will be left as-is, and the service will be stopped and
disabled.

### Configuration Verification and AppArmor

Many OSes deliver an AppArmor profile with KEA that prevents it from reading
files in `/tmp`. Since Chef creates it's config files in `/tmp`, the usual
verifier process fails as the binary cannot read the file.

If this is the case on your machine, you have several options, including a
workaround in this cookbook.

The best thing to do is to modify `/etc/apparmor.d/usr.sbin.kea*` and add a
line like:

```text
/tmp/.chef-kea* r,
```

Alternatively, you can use `node['fb_kea']['verify_aa_workaround']`.

By default this value is `false` (boolean), and does nothing. If you set this
value to `auto`, then this cookbook will attempt to determine if the work
around is needed, and if so, it'll run `aa-complain kea-dhcp<version>` before
the verify command and `aa-enforce kea-dhcp<version>` after the verify command.

If you set this value to `true` (boolean), then it will use the workaround no
matter what, without attempting to determine if it is necessary.

If you set it to any other value, it will be ignored.

In order to do this, the `verify` block for each template is a ruby block, and
thus Chef's output when the verification fails is sub-optimal. To make
everyone's life easier, our verifier block, when verification fails, logs an
INFO message including the full command used and the output. If the
verification succeeds, the command can be found in a DEBUG message.

### Control Agent Authentication

The default configuration for `control-agent` populated by this cookbook is
standard password. The password will be read by the service from
`/etc/kea/kea-api-password`. If you leave this configuration
(`node['fb_kea']['config']['control-agent']['authentication']['clients-hash']['default']`)
in place and that that file does not exist, then this cookbook will generate
the password file for you with a random password in it. This is done so that
the default configuration is both secure and also works as intended. To avoid
this behavior you can change the name of that entry in the hash to anything
else, change that entry to not be a password-file entry, or simply create that
file ahead of time.
