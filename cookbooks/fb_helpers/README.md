fb_helpers Cookbook
===================
Node helper methods for Facebook open-source cookbooks.

Requirements
------------

Attributes
----------
* node['fb_helpers']['interface_change_allowed_method']
* node['fb_helpers']['interface_start_allowed_method']
* node['fb_helpers']['managed_reboot_callback']
* node['fb_helpers']['network_changes_allowed_method']
* node['fb_helpers']['reboot_logging_callback']
* node['fb_helpers']['reboot_allowed']
* node['fb_helpers']['reboot_allowed_callback']

Usage
-----
### node methods
Simply depend on this cookbook from your metadata.rb to get these methods in
your node.

* `node.centos?`
    Is CentOS

* `node.centos5?`
    Is CentOS Linux 5

* `node.centos6?`
    Is CentOS Linux 6

* `node.centos7?`
    Is CentOS Linux 7

* `node.centos8?`
    Is CentOS Linux 8 or CentOS Stream 8

* `node.centos9?`
    Is CentOS Stream 9

* `node.centos_max_version?(v)`
    Is RHEL-compatible with a maximum version number of v

* `node.centos_min_version?(v)`
    Is RHEL-compatible with a minimum version number of v

* `node.fedora?`
    Is Fedora

* `node.fedora27?`
    Is Fedora 27

* `node.fedora28?`
    Is Fedora 28

* `node.fedora29?`
    Is Fedora 29

* `node.fedora30?`
    Is Fedora 30

* `node.fedora31?`
    Is Fedora 31

* `node.fedora32?`
    Is Fedora 32

* `node.fedora33?`
    Is Fedora 33

* `node.fedora34?`
    Is Fedora 34

* `node.fedora35?`
    Is Fedora 35

* `node.fedora36?`
    Is Fedora 36

* `node.eln?`
    Is Fedora ELN

* `node.redhat?`
    Is Redhat Enterprise Linux

* `node.redhat6?`
    Is Redhat Enterprise Linux 6

* `node.redhat7?`
    Is Redhat Enterprise Linux 7

* `node.redhat8?`
    Is Redhat Enterprise Linux 8

* `node.redhat9?`
    Is Redhat Enterprise Linux 9

* `node.rhel_max_version?(v)`
    Is Redhat Enterprise Linux with a maximum version number of v

* `node.rhel_min_version?(v)`
    Is Redhat Enterprise Linux with a minimum version number of v

* `node.rhel?`
    Is Redhat Enterprise Linux

* `node.rhel7?`
    Is Redhat Enterprise Linux 7

* `node.rhel8?`
    Is Redhat Enterprise Linux 8

* `node.rhel9?`
    Is Redhat Enterprise Linux 9

* `node.oracle?`
    Is Oracle Enterprise Linux

* `node.oracle5?`
    Is Oracle Enterprise Linux 5

* `node.oracle6?`
    Is Oracle Enterprise Linux 6

* `node.oracle7?`
    Is Oracle Enterprise Linux 7

* `node.oracle8?`
    Is Oracle Enterprise Linux 8

* `node.rhel_family?`
    Is Redhat Enterprise Linux-compatible (eg CentOS, Oracle Linux, Rocky Linux)

* `node.el_max_version?(v)`
    Is RHEL-compatible with a maximum version number of v

* `node.el_min_version?(v)`
    Is RHEL-compatible with a minimum version number of v

* `node.debian?`
    Is Debian

* `node.ubuntu?`
    Is Ubuntu

* `node.ubuntu12?`
    Is Ubuntu14

* `node.ubuntu14?`
    Is Ubuntu14

* `node.ubuntu15?`
    Is Ubuntu15

* `node.ubuntu16?`
    Is Ubuntu16

* `node.ubuntu1610?`
    Is Ubuntu16.10

* `node.ubuntu17?`
    Is Ubuntu17

* `node.ubuntu1704?`
    Is Ubuntu17.04

* `node.ubuntu18?`
    Is Ubuntu18

* `node.ubuntu1804?`
    Is Ubuntu18.04

* `node.ubuntu20?`
    Is Ubuntu20

* `node.linux?`
    Is Linux

* `node.macos?`
    Is macOS (any version)

* `node.macos10?`
    Is macOS Catalina (macOS 10)

* `node.macos11?`
    Is macOS Big Sur (macOS 11)

* `node.macos12?`
    Is macOS Monterey (macOS 12)

* `node.windows?`
    Is Windows

* `node.windows2008?`
    Is Windows 2008

* `node.windows2008r2?`
    Is Windows 2008 R2

* `node.windows2008r2sp1?`
    Is Windows 2008 R2 SP1

* `node.windows2012?`
    Is Windows 2012

* `node.windows2012r2?`
    Is Windows 2012 R2

* `node.windows2016?`
    Is Windows 2016

* `node.windows2019?`
    Is Windows 2019

* `node.aristaeos?`
    Is network switch running Arista EOS

* `node.aristaeos_4_28_or_newer?`
    Is network switch running Arista EOS and OS version is 4.28 or newer

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

   ```ruby
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

* `node.timeshard_parsed_values(start_time, duration)`
   Parse the start_time and duration values to determine the
   start_time, duration, and time_threshold; fail on invalid values.
   The timeshard value is `node.flexible_shard(duration)`.
   We take the timeshard and add it to the start time to arrive at a threshold.
   If the current system time is greater than the threshold then return true.
   The `start_time` format is `YYYY-MM-DD hh:mm:ss`, e.g.
   `2013-04-17 13:05:00`. The duration format is `Xd` or `Xh` where `d` and `h`
   are days and hours respectively, and X is the number of days or hours.
   The time threshold is the start time plus the timeshard.

* `node.in_timeshard?(start_time, duration), stack_depth=1`
   NOTE!! IF YOU USE THIS, you MUST go and clean up your code after
   `start_time+duration`!

   True if the host's timeshard is greater than the sum of the start time and
   timeshard threshold. The timeshard value is `node.flexible_shard(duration)`.
   We take the timeshard and add it to the start time to arrive at a threshold.
   If the current system time is greater than the threshold then return true.
   The `start_time` format is `YYYY-MM-DD hh:mm:ss`, e.g.
   `2013-04-17 13:05:00`. The duration format is `Xd` or `Xh` where `d` and `h`
   are days and hours respectively, and X is the number of days or hours.

* `node.shard_block?(threshold, &block)`
    This method allows you to conditionally shard chef resources

* `node.shard_over_a_week_starting(start_date)`
    Compute a shard over a week given a start date

* `node.shard_over_a_week_ending(end_date)`
    Compute a shard over a week given an end date

* `node.rollout_shard(start_date)`
    Compute a shard over a set of weekdays given a start date

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

* `node.host_chef_base_path`
   Returns the base path for the host Chef installation, i.e. `C:/chef` on
   Windows, and `/var/chef` on other platforms.

* `node.solo_chef_base_path`
   Returns the base path for the Chef Solo installation, i.e. `C:/chef/solo` on
   Windows, and `/opt/chef-solo` on other platforms.

* `node.chef_base_path`
   Returns the base path for the current Chef installation; see
   `node.host_chef_base_path` and `node.solo_chef_base_path`.

* `node.taste_tester_mode?`
   Returns true if the chef run is in taste-tester mode.  This makes it possible
   to alter whether something will happen depending on if a change is being
   tested or not.  This may be useful for stubbing out operations that would
   normally expose secrets, or for highlighting special conditions to testers.
   This should be used only under very special conditions; it makes testing
   less meaningful because it alters the outcome.

* `node.attr_lookup(path, delim: '/', default: nil)`
    Safely dig through the node's attributes based on the specified `path`,
    with the option to provide a default value in the event the key does not exist.
    Optionally a delimiter can be specified to indicate how keys are separated.
    For example, you could get the value of `node['dmi']['system']['manufacturer']`
    by calling `node.attr_lookup('dmi/system/manufacturer')`, which would return
    the value or `nil` if the value does not exist.

* `node.aws?`
   True if running on AWS EC2.

* `node.in_aws_account?(*accounts)`
   True if this node is in AWS EC2 and in an account matching one of the passed
   in account IDs.

* `node.default_package_manager`
   Return the default package manager used on the system (e.g. `dnf`, `yum`,
   `apt`, etc.) according to Chef; note that this is implemented by inspecting
   the `Chef::Package` resource, and it might deviate from the actual package
   manager used on the system in some cases.

* `node.eth_is_affinitized?`
   Returns true if the eth MSI vectors are affinitized (i.e. they are spread
   across all available CPUs).

* `node.validate_and_fail_on_dynamic_addresses`
   Fail a Chef run if a dynamic address is found on one of the network
   interfaces. Examples of dynamic addresses include SLAAC or DHCP(v6).

* `node.nw_changes_allowed?`
   True if `node['fb_helpers']['network_changes_allowed_method']` is set and
   returns true, or node is in firstboot or `FB::Helpers::NW_CHANGES_ALLOWED`
   exists.

* `node.interface_change_allowed?(interface)`
   True if `node['fb_helpers']['interface_change_allowed_method']` is set and
   returns true, or `node.nw_changes_allowed?` is true, or we're operating on
   a tunnel interface.

* `node.interface_start_allowed?(interface)`
   True if `node['fb_helpers']['interface_start_allowed_method']` is set and
   returns true, or if `node.interface_change_allowed?` is true.

* `node.disruptable?`
    A gate which can be used to limit dangerous code paths to only run during
    provisioning, boot, or other times when the host is not running a
    workload and can disrupted.  For initial boot you must
    pass `CHEF_BOOT_SERVICE=true` as an environment variable from your
    boot-time chef invocation.

### FB::Helpers
The following constants are available:

* `FB::Helpers::NW_CHANGES_ALLOWED` and `FB::Helpers::NW_CHANGES_NEEDED`
   Defines paths used by networking related cookbooks to decide whether network
   changes are allowed or need to be applied.

The following methods are available:

* `FB::Helpers.attempt_lazy { my_var }`
   Should be used when attempting to write a lazy block to an api attribute.
   If the client supports lazy attributes a DelayedEvaluator is returned, but
   if the client does not support lazy attributes the block is evaluated and
   the value is returned

* `FB::Helpers.evaluate_lazy_enumerable { my_enumerable }`
   Should be used when a potentially nested Enumerable contains a
   Chef::DelayedEvaluator that will not be directly assigned
   directly to resource attribute.  This should only be executed at converge time
   within a lazy block.

* `FB::Helpers.commentify(comment, arg)`
   Commentify takes the string in `comment` and wraps it appropriately
   for being a comment. By default it'll comment it ruby-style (leading "# ")
   with a width of 80 chars, but the arg hash can specify `start`, `finish`,
   and `width` to adjust it's behavior.

* `FB::Helpers.filter_hash(hash, filter)`
  Apply `filter` to `hash`, by recursively returning only the items from
  `hash` whose keys are also in `filter`, preserving its structure. Example:

  ```ruby
  hash = {
    'foo' => 1,
    'bar' => 2,
    'baz' => {
      'cake' => 'asdf',
      'pie' => 42,
    },
  }

  filter = ['foo', 'baz/cake']

  filter_hash(hash, filter)
  => {
       'foo' => 1,
       'baz' => {
         'cake' => 'asdf',
       },
     }
  ```

* `FB::Helpers.merge_hash(merge_onto, merge_with, overwrite_leaves)`
  Return the resulting hash from recursively merging merge_with onto
  merge_onto. Only hashes are merged -- other objects, including arrays, will
  be replaced. Leaf hashes are also merged by default; this can be changed
  with overwrite_leaves, which will replace them instead.

* `FB::Helpers.merge_hash!(merge_onto, merge_with, overwrite_leaves)`
  Same as `merge_hash()`, but update the merge_onto hash in place.

* `FB::Helpers.parse_json(json_string, top_level_class, fallback)`
  Parse a JSON string and return the appropriate object, while validating
  that it matches what is expected. If `fallback` is true, return an empty
  object in case of errors.

* `FB::Helpers.parse_json_file(path, top_level_class, fallback)`
  Parse a JSON file and return the appropriate object, while validating that
  it matches what is expected. If `fallback` is true, return an empty object
  in case of errors.

* `FB::Helpers.parse_simple_keyvalue_file(path, options)`
  Parse a simple key/value file with the form key=value and return a hash of
  key/value pairs, stripping leading and trailing whitespace unless otherwise
  specified. Accepts the following options:
  * `:force_downcase` - if true, coerces keys into lower case.
  * `:empty_value_is_nil` - if true, coerces empty string values to nil.
  * `:include_whitespace` - if true, treats whitespace in the key/value pairs
    as semantic
  * `:exclude_quotes` - if true, removes surrounding quotes
  * `:fallback` - if true, return an empty hash in case of errors.

* `FB::Helpers.parse_timeshard_start(time)`
  Takes a time string and converts its contents to a unix timestamp,
   to be used in computing timeshard information.

* `FB::Helpers.parse_timeshard_duration(duration)`
  Takes a duration string and converts its contents to a to an int
  to be used in computing timeshard information

* `FB::Helpers.safe_dup(thing)`
  Wrapper around `dup` that always returns a valid object, even for things
  that do not support `dup`.

* `FB::Helpers.sysnative_path`
  Determines the sysnative path on Windows

* `FB::Helpers.warn_to_remove(stack_depth, message)`
  Used to discover obsolete code. Defaults message to warning about time
  sharding code

* `FB::Helpers.user_exist?('someuser')`
  Test if a user is defined on the system. Usually this would be checked by
  looking at `node['etc']['passwd']` but if the user was added during the same
  chef run then ohai won't have it, unless ohai was reloaded.

* `FB::Helpers.group_exist?('groupname')`
  Test if a group is defined on the system. Usually this would be checked by
  looking at `node['etc']['group']` but if the group was added during the same
  chef run then ohai won't have it, unless ohai was reloaded.

* `FB::Helpers.get_hwaddr(interface)`
  Return the hardware (MAC) address of the interface or nil if no such interface
  was found.

* `FB::Version.new(version)`
   Helper class to compare software versions. Sample usage:

   ```ruby
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

#### fb_helpers_serialize
Use the `fb_helpers_serialize` resource to serialize an Object to a JSON file
on disk. This can be useful, for example, to checkpoint a data structure at a
given point in the run to ease troubleshooting. Note that if you feed a large
hash to this (e.g. the whole node object), it will be a very expensive
operation. To mitigate this the ability to filter Hash objects before writing
is provided.

```ruby
fb_helpers_serialize '/tmp/foo.json' do
  object foo
  filter foo_filter
  owner 'root'
  group 'root'
  mode '0644'
end
```

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

#### fb_helpers_gated_template
Use `fb_helpers_gated_template` for network configuration templates where you
need to block changes unless certain conditions are met. In particular,
`fb_helpers_gated_template` will put down the `FB::Helpers::NW_CHANGES_NEEDED`
file when changes need to be applied but are not yet written, and remove the
`FB::Helpers::NW_CHANGES_ALLOWED` and `FB::Helpers::NW_CHANGES_NEEDED` files
when the changes are applied.

The syntax mostly follows a regular template resource, with the addition of
`allow_changes` which sets the conditions for which changes are allowed.

```ruby
fb_helpers_gated_template '/etc/foo.network' do
  allow_changes true, false
  path          String # defaults to template name
  source        String
  variables     Hash
  owner         String
  group         String
  mode          String
  gated_action  Symbol # same actions as regular templates
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
explanatory message), `action` (the actual action being taken, e.g. `reboot`).
