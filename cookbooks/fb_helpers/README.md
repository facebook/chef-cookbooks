fb_helpers Cookbook
===================
Node helper methods for Facebook open-source cookbooks.

Requirements
------------

Attributes
----------
* node['fb_helpers']['managed_reboot_callback']
* node['fb_helpers']['reboot_logging_callback']
* node['fb_helpers']['reboot_allowed']

Usage
-----
### node methods
Simply depend on this cookbook from your metadata.rb to get these methods in
your node.

* `node.centos?`
    Is CentOS

* `node.centos5?`
    Is CentOS5

* `node.centos6?`
    Is CentOS6

* `node.centos7?`
    Is CentOS7

* `node.centos8?`
    Is CentOS8

* `node.fedora?`
    Is Fedora

* `node.fedora27?`
    Is Fedora27

* `node.fedora28?`
    Is Fedora28

* `node.fedora29?`
    Is Fedora29

* `node.redhat?`
    Is Redhat Enterprise Linux

* `node.debian?`
    Is Debian

* `node.ubuntu?`
    Is Ubuntu

* `node.ubuntu14?`
    Is Ubuntu14

* `node.ubuntu15?`
    Is Ubuntu15

* `node.ubuntu16?`
    Is Ubuntu16

* `node.ubuntu18?`
    Is Ubuntu18

* `node.ubuntu20?`
    Is Ubuntu20

* `node.linux?`
    Is Linux

* `node.macos?`
    Is Mac OS X

* `node.windows?`
    Is Windows

* `node.aristaeos?`
    Is network switch running Arista EOS

* `node.embedded?`
    Is embedded Linux, implies 'node.aristaeos?'. These devices likely have
    minimal packages installed, little space, and/or some non-persistent
    filesystems.

* `node.systemd?`
    True if the node uses systemd as their init system.

* `node.container?`
    True if the node is in a container.

* `node.virtual?`
    Is a guest.

* `node.efi?`
    Is an EFI machine

* `node.aarch64?`
    Is an ARM64 machine

* `node.x64?`
    Is an x86_64 machine

* `node.cgroup_mounted?`
    Returns true if the cgroup hierarchy is mounted at `/sys/fs/cgroup`

* `node.cgroup1?`
    Returns true if the legacy cgroup hierarchy (cgroup v1) is in use

* `node.cgroup2?`
    Returns true if the unified cgroup hierarchy (cgroup v2) is in use

* `node.device_of_mount(m)`
    Take a string representing a mount point, and return the device it resides
    on.

* `node.device_formatted_as?(device, fstype)`
    Returns true if device is formatted with the given filesystem type.

* `node.fs_size_kb(mount_point)`
    Returns the size of a filesystem mounted at `mount_point` in KB.

* `node.fs_size_gb(mount_point)`
    Returns the size of a filesystem mounted at `mount_point` in GB.

* `node.fs_available_kb(mount_point)`
    Returns the available size of a filesystem mounted at `mount_point` in KB.

* `node.fs_available_gb(mount_point)`
    Returns the available size of a filesystem mounted at `mount_point` in GB.

* `node.fs_value(mount_point, value)`
    Returns information about a filesystem mounted at `mount_point`, where
    information is defined by `value`. Allowed values for `value` are:
      `size` - size in KB
      `available` - available space in KB
      `used` - used space in KB
      `percent` - used space as a percent (returned as a whole number, i.e. 15)

* `node.resolve_dns_name(hostname, brackets, force_v4)`
   Resolves hostname and returns back one IP address.
   If the host is IPv6-capable, IPv6 address is returned. The default is to
   return IP address only, but if the second parameter (brackets) is set to
   true, the IPv6 address gets wrapped in square brackets. If DNS name does
   not exist or only resolves to an ipv6 address while your host is not
   IPv6-capable, a `SocketError` is raised.
   `force_v4` is set to false by default, if set to true then the IPv4 address
   will be returned.

* `node.get_flexible_shard(shard_size)`
   Returns the node's shard in a flexible shard setup.  These shards allow you
   to specify an arbitrary size (limited to 2^28) for the number of possible
   buckets.  Let's say that you want a consistent shard that correlates a
   minute in the whole day (1,400 min/day).  You would use this in your code:

   ```
     node.get_flexible_shard(1440)
   ```

   This helps also to release code to shards smaller than 1% of the fleet,
   e.g. `node.get_flexible_shard(10000)` for getting your shard in steps
   of one ten-thousandth.

* `node.in_flexible_shard?(shard, shard_size)`
   True if the flexible shard we are in is less-than-or-equal to `shard`.  In
   other words, `node.in_flexible_shard?(24, 1000)` is true if you are in
   shards 0-24 per-thousandth (the equivalent to 0%-2.4%).  This sharding is
   *not* compatible with the `node.in_shard?()` implementation, so please choose
   one or the other when starting your experiment.

* `node.get_shard()`
   Wrapper around `node.get_flexible_shard` that sets `shard_size` to 100. This
   is the "basic" shard that roughly maps to a percentage.

* `node.in_shard?(shard)`
   Wrapper around `node.in_flexible_shard?` that sets `shard_size` to 100.
   Shards are 0-indexed, so the valid shards are 0-99. As such, shard `N` is
   approximately `(N+1)%`, so shard 0 is approximately 1%.

* `node.in_timeshard?(start_time, duration)`
   NOTE!! IF YOU USE THIS, you MUST go and clean up your code after
   `start_time+duration`!

   True if the host's timeshard is greater than the sum of the start time and
   timeshard threshold. The timeshard value is `node.flexible_shard(duration)`.
   We take the timeshard and add it to the start time to arrive at a threshold.
   If the current system time is greater than the threshold then return true.
   The `start_time` format is `YYYY-MM-DD hh:mm:ss`, e.g.
   `2013-04-17 13:05:00`. The duration format is `Xd` or `Xh` where `d` and `h`
   are days and hours respectively, and X is the number of days or hours.

* `node.firstboot_any_phase?`
   Returns `true` if we're in any of firstboot steps

* `node.firstboot_os?`
   Shortcut for `node['fb_init']['firstboot_os']`

* `node.firstboot_tier?`
   Shortcut for `node['fb_init']['firstboot_tier']`

* `node.solo?`
   Returns `true` if a chef run is using chef-solo. Shortcut for
   `Chef::Config[:solo]` or `Chef::Config[:local_mode]`

* `node.root_user`
   Returns the platform-specific username for the `root` account.

* `node.root_group`
   Returns the platform-specific group for the `root` account.

* `node.filesystem_data`
   Will return either `node['filesystem']` or `node['filesystem2']`, whichever
   is the newer format.

* `node.rpm_version(name)`
   Returns the version of an RPM if installed, or `nil` if not installed. This
   method follows changes to the RPM database during a run if a package is
   installed or removed. For most use cases, please use `node['packages']` as
   it is cheaper.

* `node.selinux_mode`
   Returns the current SELinux mode (one of `enforcing`, `permissive`,
   `disabled` or `unknown`).

* `node.selinux_policy`
   Returns the loaded SELinux policy name, or `nil` if it cannot be determined.

* `node.selinux_enabled?`
   Returns true if SELinux is not disabled (meaning, it's running in enforcing
   or permissive mode), otherwise returns false.

### FB::Helpers
The following methods are available:

* `FB::Helpers.commentify(comment, arg)`
   Commentify takes the string in `comment` and wraps it appropriately
   for being a comment. By default it'll comment it ruby-style (leading "# ")
   with a width of 80 chars, but the arg hash can specify `start`, `finish`,
   and `width` to adjust it's behavior.
* `FB::Version.new(version)`
   Helper class to compare software versions. Sample usage:

   ```
   FB::Version.new('1.3') < FB::Version.new('1.21')
   => true
   FB::Version.new('4.5') < FB::Version.new('4.5')
   => false
   FB::Version.new('3.3.10') > FB::Version.new('3.4')
   => false
   FB::Version.new('10.2') >= FB::Version.new('10.2')
   => true
   FB::Version.new('1.2.36') == FB::Version.new('1.2.36')
   => true
   FB::Version.new('3.3.4') <= FB::Version.new('3.3.02')
   => false
   ```

### Custom resources
The following custom resources are available

#### fb_helpers_reboot
Use the `fb_helpers_reboot` resource if you need to indicate to an external
service that the host needs to be rebooted and when that reboot action should
be handled. Example:

```ruby
fb_helpers_reboot 'reboot to enable cgroup2' do
  not_if { node.cgroup2? }
  required false
  action :deferred
end
```

This custom resource implements a few different ways to reboot as actions.

* Action `deferred`:
    Reboot will be queued and evaluated at the end of the Chef run (via the
    `:process_deferred` action).

    If you want all Chef runs to fail until the host is rebooted successfully,
    set the `required` attribute to true. If you commit to handle the reboots
    via some other means, set `required` to false and Chef runs will continue
    to succeed as normal.

* Action `managed_now`:

    NOTE THAT THIS RULE INTENTIONALLY CRASHES CHEF!

    Perform a managed reboot, where an external entity will perform the reboot,
    watch the host come back and re-run Chef. To use this you most likely want
    to set `node['fb_helpers']['managed_reboot_callback']` to a `proc` that can
    signal the external entity.

* Action `now` (default):

    NOTE THAT THIS RULE INTENTIONALLY CRASHES CHEF!

    If you want to cause a reboot, cause it *as early as possible* in a Chef
    run so that you don't end up discarding a bunch of queued-up notifications.

    This custom resource will abort the current Chef run and reboot the system
    if reboots are allowed.

    If reboots are not allowed, by default, this custom resource will crash. If
    you want Chef to keep going even if it can't reboot, set the attribute
    `required` to false.

* Action `rtc_wakeup`:

    NOTE THAT THIS RULE INTENTIONALLY CRASHES CHEF!

    Use the Linux RTC to wake up the server from a full power-off state after a
    specified wait time. The default wait time is 120 seconds and can be
    customized via the `wakeup_time_secs` property.

    The power-off will only occur if the `rtcwake` command is supported on
    the server and executes successfully.

    This custom resource will crash if reboots are not allowed, or if the
    system is in firstboot.

* Action `process_deferred`:
    This is the counterpart of `action :deferred` and is what processes any
    enqueued reboots. It is meant to be used at the end of `fb_init`, and by
    default will fail the Chef run to prevent misuse unless the special
    property `__fb_helpers_internal_allow_process_deferred` is set to true.

To prevent spurious Chef runs once a reboot request has been issued, it is
recommended to check for the override flag file in `/etc/chef/client.rb`:

```ruby
# use /tmp/chef_reboot_override on OSX
if File.exist?('/dev/shm/chef_reboot_override')
  abort 'WARN: chef_reboot_override is in effect - aborting until after reboot'
end
```

### Reboot control
If it's safe for Chef to reboot your host, set `reboot_allowed` to true in
your cookbook:

```ruby
node.default['fb_helpers']['reboot_allowed'] = true
```

Note that if Chef reboots the host during a firstboot run, that run will be
considered as failed, and the *next* Chef run will be in the same phase. For
example, if a reboot is issued during a firstboot OS run, the next Chef run
once the host comes back from the reboot will also be an OS run; the one after
that, assuming the OS run has succeeded, will be a Tier run.

### Reboot logging
If you'd like to log whenever a reboot is triggered by `fb_helpers_reboot` you
can set `node['fb_helpers']['reboot_logging_callback']` to perform the logging.
This should be a proc or library taking `node` (the node object), `reasons` (an
explanatory message), `action` (the actual action being taked, e.g. `reboot`).
