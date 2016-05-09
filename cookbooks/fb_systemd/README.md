fb_systemd Cookbook
====================

Requirements
------------

Attributes
----------
* node['fb_systemd']['default_target']
* node['fb_systemd']['modules']
* node['fb_systemd']['journald'][$OPTION]
* node['fb_systemd']['logind']['enable']
* node['fb_systemd']['tmpfiles'][$FILE]
* node['fb_systemd']['preset'][$SERVICE]
* node['fb_systemd']['manage_systemd_packages']

Usage
-----
This cookbooks manages systemd. It is only supported on CentOS 7 or later. Just
include `fb_systemd` in your runlist to use it.

### Providers

* a `fb_systemd_reload` LWRP to safetly trigger a daemon reload for a systemd
  instance (at the system or user level)

    fb_systemd_reload 'reload systemd' do
      instance 'user'
      user 'dcavalca'
    end

  The `instance` attribute can be `system` or `user` and defines which instance
  will be reloaded. For user instances, the optional attribute `user` defines
  which user instance should be reloaded; if it's omitted or `nil`, the LWRP
  will reload systemd for all active user sessions.

* two resources (`fb_systemd_reload[system instance]` and 
  `fb_systemd_reload[all user instances]`) that other recipes can notify 
  whenever they need to reload systemd (e.g. because the added or modified a 
  unit); these are built on top of the `fb_systemd_reload` LWRP.

### Default Target
The default systemd target can be configured with
`node['fb_systemd']['default_target']`. It defaults to
`/lib/systemd/system/multi-user.target`.

### system configuration
You can tune system-level defaults for systemd by using the attribute 
`node['fb_systemd']['system']`. This is useful e.g. to set system-level limits
for services (as systemd doesn't enforce PAM limits set via `fb_limits` for 
system services), such as:

  node.default['fb_systemd']['system']['DefaultLimitNOFILE'] = 65535 

Refer to the systemd documentation 
(https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html) for
more details on what settings are available.

### Journal configuration
By default we configure the journal to 'auto' storage (disk if directory exists,
or ram otherwise, default for most distros). You can change these settings and
more through the attribute `node['fb_systemd']['journald']`.

Refer to the systemd documentation
(https://www.freedesktop.org/software/systemd/man/journald.conf.html) for more
details on possible configurations.

### logind configuration
You can choose whether or not to enable `systemd-logind` with the
`node['fb_systemd']['logind']['enable']` attribute. Note that for user sessions
to work, this is required, and it defaults to true.

### Modules
Use `node['fb_systemd']['modules']` to tell systemd to load a list of
kernel modules on startup. Note that in most cases you probably want to use
`node['fb_modprobe']['modules_to_load_on_boot']` instead as that'll work
transparently on non-systemd hosts as well.

### tmpfile configuration
Use `node['fb_systemd']['tmpfiles']` to control the creation, deletion
and cleaning of volatile and temporary files. For example:

  node.default['fb_systemd']['tmpfiles']['/run/user'] = {
    'type' => 'd',
    'mode' => '0755',
    'uid' => 'root',
    'gid' => 'root',
    'age' => '10d',
    'argument' => '-',
  }

If `type` is omitted, it defaults to `f` (create a regular file); if `path` is
omitted, it defaults to the configuration key (i.e. `/run/user` in the example).
If any other argument is omitted, it defaults to `-`. Refer to the systemd
documentation (http://www.freedesktop.org/software/systemd/man/tmpfiles.d.html)
for more details on how to use tmpfiles and the meaning of the various options.

### preset
You can add preset settings to `node['fb_systemd']['preset']`. As an exmaple to
disable a preset:

    node.default['fb_systemd']['preset']['tmp.mount'] = 'disable'

Possible values can be found at
https://www.freedesktop.org/software/systemd/man/systemd.preset.html

They are installed in /etc/systemd/system-preset/00-fb_systemd.preset which will
take precedence over other preset files.

### packages
By default this cookbook keeps the systemd packages up-to-date, but if you
want to manage them locally, simply set
`node['fb_systemd']['manage_systemd_packages']` to false.
