fb_helpers Cookbook
===================
Node helper methods for Facebook open-source cookbooks.

Requirements
------------

Attributes
----------

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

* `node.debian?`
    Is Debian

* `node.ubuntu?`
    Is Ubuntu

* `node.linux?`
    Is Linux

* `node.macosx?`
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

*  `node.resolve_dns_name(hostname, brackets, force_v4)`
    Resolves hostname and returns back one IP address.
    If the host is IPv6-capable, IPv6 address is returned. The default is to
    return IP address only, but if the second parameter (brackets) is set to
    true, the IPv6 address gets wrapped in square brackets. If DNS name does
    not exist or only resolves to an ipv6 address while your host is not
    IPv6-capable, a `SocketError` is raised.
    `force_v4` is set to false by default, if set to true then the IPv4 address
    will be returned.

*  `node.get_flexible_shard(shard_size)`
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

*  `node.in_flexible_shard?(shard, shard_size)`
    True if the flexible shard we are in is less-than-or-equal to `shard`.  In
    other words, `node.in_flexible_shard?(24, 1000)` is true if you are in
    shards 0-24 per-thousandth (the equivalent to 0%-2.4%).  This sharding is
    *not* compatible with the `node.in_shard?()` implementation, so please choose
    one or the other when starting your experiment.

*  `node.get_shard()`
    Wrapper around `node.get_flexible_shard` that sets `shard_size` to 100. This
    is the "basic" shard that roughly maps to a percentage.

*  `node.in_shard?(shard)`
    Wrapper around `node.in_flexible_shard?` that sets `shard_size` to 100.
    Shards are 0-indexed, so the valid shards are 0-99. As such, shard `N` is
    approximately `(N+1)%`, so shard 0 is approximately 1%.

### FB::Helpers
The following methods are available:

*  `FB::Helpers.commentify(comment, arg)`
    Commentify takes the string in `comment` and wraps it appropriately
    for being a comment. By default it'll comment it ruby-style (leading "# ")
    with a width of 80 chars, but the arg hash can specify `start`, `finish`,
    and `width` to adjust it's behavior.
*  `FB::Version.new(version)`
   Helper class to compare software versions. Sample usage:

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
