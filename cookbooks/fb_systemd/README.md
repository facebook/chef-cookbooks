fb_systemd Cookbook
====================

Requirements
------------

Attributes
----------
* node['fb_systemd']['default_target']
* node['fb_systemd']['modules']
* node['fb_systemd']['system']
* node['fb_systemd']['user']
* node['fb_systemd']['udevd']['config']
* node['fb_systemd']['udevd']['hwdb']
* node['fb_systemd']['udevd']['rules']
* node['fb_systemd']['journald']['config']
* node['fb_systemd']['journal-gatewayd']['enable']
* node['fb_systemd']['journal-remote']['enable']
* node['fb_systemd']['journal-remote']['config']
* node['fb_systemd']['journal-upload']['enable']
* node['fb_systemd']['journal-upload']['config']
* node['fb_systemd']['logind']['enable']
* node['fb_systemd']['logind']['config']
* node['fb_systemd']['networkd']['enable']
* node['fb_systemd']['resolved']['enable']
* node['fb_systemd']['resolved']['config']
* node['fb_systemd']['timesyncd']['enable']
* node['fb_systemd']['timesyncd']['config']
* node['fb_systemd']['coredump']
* node['fb_systemd']['tmpfiles']
* node['fb_systemd']['preset']
* node['fb_systemd']['manage_systemd_packages']
* node['fb_systemd']['boot']['enable']
* node['fb_systemd']['boot']['path']
* node['fb_systemd']['boot']['loader']
* node['fb_systemd']['boot']['entries']

Usage
-----
This cookbooks manages systemd. It is only supported on systemd-enabled 
distributions (e.g. CentOS 7 or Debian 8). Just include `fb_systemd` in your 
runlist to use it.

### FB::Systemd
The following methods are available:

* `FB::Systemd.path_to_unit(path, unit_type)`
  Convert a given `path` to a unit name of `unit_type` type.

     FB::Systemd.path_to_unit('/dev/mapper/dm-0', 'swap')
     => dev-mapper-dm\x2d0.swap

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

### System and session configuration
You can tune system-level or session-level defaults for systemd by using the 
attributes `node['fb_systemd']['system']` and `node['fb_systemd']['user']`.
This is useful e.g. to set system-level limits for services (as systemd doesn't
enforce PAM limits set via `fb_limits` for system services), such as:

    node.default['fb_systemd']['system']['DefaultLimitNOFILE'] = 65535 

Refer to the 
[systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html) 
for more details on what settings are available.

### udevd configuration
Udevd is a critical system daemon and cannot be disabled. General udev settings
can be configured via `node['fb_systemd']['journald']['config']`, as described 
in the 
[udev documentation](https://www.freedesktop.org/software/systemd/man/udev.conf.html).

Additional entries to the hardware database can be entered using the
`node['fb_systemd']['udevd']['hwdb']` attribute, as described in the
[hwdb documentation](https://www.freedesktop.org/software/systemd/man/hwdb.html).
Example:

    node.default['fb_systemd']['udevd']['hwdb']['evdev:input:b0003v05AFp8277*'] = {
      'KEYBOARD_KEY_70039' => 'leftalt',
      'KEYBOARD_KEY_700e2' => 'leftctrl',
    }

Additional udev rules can be defined using the 
`node['fb_systemd']['udevd']['rules']` attribute, as described in the
[udev documentation](https://www.freedesktop.org/software/systemd/man/udev.html).
Example:

    node.default['fb_systemd']['udevd']['rules'] += [
      'KERNEL=="fd[0-9]*", OWNER="john"',
    ]

### journald configuration
Journald is a critical system daemon and cannot be disabled. By default we 
configure journald to use the 'auto' storage (disk if the log directory exists,
or ram otherwise, which is the default for most distros). You can change these 
settings and more through `node['fb_systemd']['journald']['config']`.

Refer to the 
[journald documentation](https://www.freedesktop.org/software/systemd/man/journald.conf.html)
for more details on possible configurations.

### journal-gatewayd configuration
You can choose whether or not to enable `systemd-journal-gatewayd` with the
`node['fb_systemd']['journal-gatewayd']['enable']` attribute, which defaults
to `false`. Please refer to the
[journal-gatewayd documentation](https://www.freedesktop.org/software/systemd/man/systemd-journal-gatewayd.html)
for more information.

### journal-remote configuration
You can choose whether or not to enable `systemd-journal-remote` with the
`node['fb_systemd']['journal-remote']['enable']` attribute, which defaults
to `false`. journal-remote can be configured using the 
`node['fb_systemd']['journal-remote']['config']` attribute, according to the
[journal-remote documentation](https://www.freedesktop.org/software/systemd/man/journal-remote.conf.html).

### journal-upload configuration
You can choose whether or not to enable `systemd-journal-upload` with the
`node['fb_systemd']['journal-upload']['enable']` attribute, which defaults
to `false`. journal-upload can be configured using the
`node['fb_systemd']['journal-upload']['config']` attribute, according to the
[journal-upload documentation](https://www.freedesktop.org/software/systemd/man/systemd-journal-upload.html).

### logind configuration
You can choose whether or not to enable `systemd-logind` with the
`node['fb_systemd']['logind']['enable']` attribute. Note that for user sessions
to work, this is required, and it defaults to true. Logind can be configured
using the `node['fb_systemd']['logind']['config']` attribute, according to the
[logind documentation](https://www.freedesktop.org/software/systemd/man/logind.conf.html).

### networkd configuration
You can choose whether or not to enable `systemd-networkd` with the
`node['fb_systemd']['networkd']['enable']` attribute, which defaults to `false`.

Note that this cookbook does not manage network configuration profiles. If you 
drop `netdev`, `link`, `network` definitions under `/etc/systemd/network` from
another cookbook you'll want to request a restart of the `systemd-networkd`
service.

### resolved configuration
You can choose whether or not to enable `systemd-resolved` with the
`node['fb_systemd']['resolved']['enable']` attribute, which defaults to `false`.
Note that this will also enable the `nss-resolve` resolver in 
`/etc/nsswitch.conf` in place of the glibc `dns` one (using the API provided by
`fb_nsswitch`). Resolved can be configured using the
`node['fb_systemd']['resolved']['config']` attribute, as described in the
[resolved documentation](https://www.freedesktop.org/software/systemd/man/resolved.conf.html).

Note that this cookbook does not manage `/etc/resolv.conf`. If you're using 
resolved, you probably want to make that a symlink to 
`/run/systemd/resolve/resolv.conf`. 

### timesyncd configuration
You can choose whether or not to enable `systemd-timesyncd` with the
`node['fb_systemd']['timesyncd']['enable']` attribute, which defaults to `false`.
You'll want to disable this if you're running another NTP daemon such as ntpd.
Timesyncd can be configured with the `node['fb_systemd']['timesyncd']['config']`
attribute, as described in the
[timesyncd documentation](https://www.freedesktop.org/software/systemd/man/timesyncd.conf.html).

### Coredump configuration
systemd provides a facility for collecting and analyzing coredumps of system
services. This can be configured using the `node['fb_systemd']['coredump']`
attribute, as described in the
[coredump documentation](https://www.freedesktop.org/software/systemd/man/coredump.conf.html).

### Kernel modules
Use `node['fb_systemd']['modules']` to tell systemd to load a list of
kernel modules on startup. Note that in most cases you probably want to use
`node['fb_modprobe']['modules_to_load_on_boot']` instead as that'll work
transparently on non-systemd hosts as well.

### tmpfiles configuration
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
If any other argument is omitted, it defaults to `-`. Refer to the
[tmpfiles documentation](http://www.freedesktop.org/software/systemd/man/tmpfiles.d.html)
for more details on how to use tmpfiles and the meaning of the various options.

### Presets
You can add preset settings to `node['fb_systemd']['preset']`. As an example to
disable a unit:

    node.default['fb_systemd']['preset']['tmp.mount'] = 'disable'

Possible values can be found at
https://www.freedesktop.org/software/systemd/man/systemd.preset.html

They are installed in `/etc/systemd/system-preset/00-fb_systemd.preset` which 
will take precedence over other preset files.

### Packages
By default this cookbook keeps the systemd packages up-to-date, but if you
want to manage them locally, simply set
`node['fb_systemd']['manage_systemd_packages']` to false.

### Boot
You can choose whether or not to enable `systemd-boot` with the
`node['fb_systemd']['boot']['enable']` attribute, which defaults to `false`.
This controls whether `systemd-boot` will be installed, or whether it will be
updated on package updates. Note that `systemd-boot` only works on EFI systems
and requires a mounted EFI Service Partition (ESP). The cookbook will attempt
to autodetect the ESP mountpoint, which can be overwritten with 
`node['fb_systemd']['boot']['path']`. General loader settings can be controlled
with `node['fb_systemd']['boot']['loader']`. Finally, loader entries can be 
defined by populating `node['fb_systemd']['boot']['entries']`, e.g. by writing
a `ruby_block` to scan for installed kernels and set the appropriate entries.
Please refer to the 
[upstream documentation](https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/)
for more details.
