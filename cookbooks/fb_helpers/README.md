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

* `node.yocto?`
    Is a Yocto platform

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
