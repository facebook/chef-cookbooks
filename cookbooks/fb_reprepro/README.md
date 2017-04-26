fb_reprepro Cookbook
====================
Installs and configures reprepro, a tool to manage a repository of Debian
packages.

Requirements
------------

Attributes
----------
* node['fb_reprepro']['user']
* node['fb_reprepro']['group']
* node['fb_reprepro']['distributions'][$NAME]
* node['fb_reprepro']['updates'][$NAME]
* node['fb_reprepro']['pulls'][$NAME]
* node['fb_reprepro']['incoming'][$NAME]
* node['fb_reprepro']['options'][$KEY][$VAL]

Usage
-----
Including `fb_reprepro` will install the `reprepro` package and setup a
repository tree for the under `node['fb_reprepro']['options']['basedir']`. This
will be owned by the user/group set in `node['fb_reprepro']['user']` and
`node['fb_reprepro']['group']`. These default to `root`, but it is recommented
to create a non-privileged user and update these accordingly. Other general
reprepro settings can be defined in `node['fb_reprepro']['options']`.

This cookbook does not setup a webserver, you'll have to do that separately if
you'd like to make the repository available to APT clients.

### Distributions, updates and pulls
Refer to the
[upstream documentation](http://mirrorer.alioth.debian.org/reprepro.1.html)
for details on how to setup distributions, updates and pulls. These are
controlled by the respective attributes. Example:

```ruby
node.default['fb_reprepro']['distributions']['jessie'] = {
  'Codename' => 'jessie'
  'Architectures' => %w{i386 amd64 source}
  'Components' => %w{main contrib non-free}
  'UDebComponents' => 'main'
  'SignWith' => 'F3EFDBD9'
  'DebIndices' => %w{Packages Release . .gz .bz2}
  'UDebIndices' => %w{Packages . .gz .bz2}
  'DscIndices' => %w{Sources Release .gz .bz2}
  'Contents' => %w{. .gz .bz2}
}
```

### Incoming
Reprepro supports automatically importing packages from an `incoming` queue.
This is setup via the `node['fb_reprepro']['incoming']` attribute. Example:

```ruby
node.default['fb_reprepro']['incoming']['default'] = {
  'Name' => 'default',
  'IncomingDir' => 'incoming',
  'TempDir' => 'tmp',
  'Allow' => 'jessie',
  'Cleanup' => 'on_deny on_error',
}
```

Note that the actual incoming processing will have to be handled separately,
e.g. using a cronjob.
