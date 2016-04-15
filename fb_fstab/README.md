fb_fstab coookbook
============
Support for full mount/fstab control.

Requirements
------------

Attributes
----------
* node['fb_fstab']['enable_remount']
* node['fb_fstab']['enable_unmount']
* node['fb_fstab']['umount_ignores']['devices']
* node['fb_fstab']['umount_ignores']['device_prefixes']
* node['fb_fstab']['umount_ignores']['types']
* node['fb_fstab']['umount_ignores']['mount_points']
* node['fb_fstab']['mounts'][$NAME]['device']
* node['fb_fstab']['mounts'][$NAME]['mount_point']
* node['fb_fstab']['mounts'][$NAME]['type']
* node['fb_fstab']['mounts'][$NAME]['opts']
* node['fb_fstab']['mounts'][$NAME]['dump']
* node['fb_fstab']['mounts'][$NAME]['pass']
* node['fb_fstab']['mounts'][$NAME]['only_if']
* node['fb_fstab']['mounts'][$NAME]['mp_owner']
* node['fb_fstab']['mounts'][$NAME]['mp_group']
* node['fb_fstab']['mounts'][$NAME]['mp_mode']
* node['fb_fstab']['mounts'][$NAME]['remount_with_umount']
* node['fb_fstab']['mounts'][$NAME]['enable_remount']
* node['fb_fstab']['mounts'][$NAME]['allow_mount_failure']

Usage
-----
fb_fstab will look at the state of the system and attempt to populate the basic
system mounts into `node['fb_fstab']['mounts']` for you. You may then
add whatever filesystems you would like mounted and `fb_fstab` will, for each
entry in the hash:
* populate `/etc/fstab` for you
* create the `mount_point` (but not parents) if it doesn't exist
  (if you need parents created, please file a task against chef oncall)
* mount the filesystem

### Global Options

`node['fb_fstab']['enable_remount']` controls whether `fb_fstab` will ever
attempt to remount filesystems to update options (defaults to `false`). If this
is `false`, no remounts will ever be attempted. If this is `true`, we will
attempt to remount filesystems as necessary unless a given `mounts` entry sets
`enable_remount` to `false`. In other words both
`node['fb_fstab']['enable_remount']` *and*
`node['fb_fstab']['mounts'][$NAME']['enable_remount']` must be true for
`fb_fstab` to remount.

`node['fb_fstab']['enable_unmount']` controls whether `fb_fstab` will
ever attempt to unmount filesystems that are no longer represented in
the `node['fb_fstab']['mounts']` structure. The default is `false`.

`node['fb_fstab']['umount_ignores']` is a hash of things to ignore
on unmounting, even if unmounting is enabled. A list of defaults is in
attributes, you may add or remove from this as you see fit. For example, you
may want:

    node.default['fb_fstab']['umount_ignores']['devices'] << '/dev/sdb'

### Filesystem Options
The following options map directly to their `/etc/fstab` counterparts, so see
the man page for further information on them:
  * `mount_point`
  * `device`
  * `type` (defaults to `auto` if you do not specify)
  * `opts` (defaults to `default` if you don't specify)
  * `dump` (defaults to `0` if you don't specify)
  * `pass` (defaults to `2` if you don't specify)

The following are additional flags to `fb_fstab`:
  * `remount_with_umount` - by default, we remount with `mount -o remount`, but
                            if this is set, we will `umount` and `mount`
  * `enable_remount` - defaults to `true`, set to `false` if this FS should
                       never be remounted
  * `mp_owner` - mountpoint owner
  * `mp_group` - mountpoint owner
  * `mp_mode` - mountpoint owner
  * `only_if` - this takes a Proc to test at runtime much like typical
                Chef resources, except it only takes a Proc.
  * `allow_mount_failure` - Allow failure to mount this disk. It will still
    show up in `/etc/fstab`, but Chef will not crash if mounting fails. This
    option is designed for teams who can handle data-disk failures gracefully
    and don't want it to bother Chef.

Example:

    node.default['fb_fstab']['mounts']['foobar'] = {
      'device' => 'foobar-tmpfs',
      'type' => 'tmpfs',
      'opts' => 'size=36G',
      'mount_point' => '/mnt/foobar-tmpfs',
    }

Note that you may override an existing 'core' mount by simply specifying
it in your `node['fb_fstab']['mounts']` structure with the same device
and mount point.

Since we must make the mountpoint for you, due to ordering, you may specify
`mp_owner`, `mp_group`, and `mp_mode` in the hash as well. We will not enforce
these on an ongoing basis (partly becuase you can't change things under mounts,
and partly because you can do this on your own), but we will ensure if we
need to create the directory for you, we make it the way you want.

Using `only_if` is slightly different than with resources, and looks like this:

    node.default['fb_fstab']['mounts']['foobar'] = {
      'only_if' => proc { foo == bar },
      'device' => 'foobar-tmpfs',
      'type' => 'tmpfs',
      'opts' => 'size=36G',
      'mount_point' => '/mnt/foobar-tmpfs',
    }

Things that fail the only_if will not show up in /etc/fstab or be mounted.

### Base-OS filesystems
`fb_fstab` determines the base filesystems (root, boot, swap, etc.) that would
come from the original installation from `/etc/.fstab.chef`. It is recommended
you have your instalation system create this file (e.g in an Anaconda
post-script) with something like:

    grep -v '^#' /etc/fstab > /etc/.fstab.chef
    chmod 400 /etc/.fstab.chef

If such a file does not exist, `fb_fstab` will do it's best to generate one by
pulling things it believes are "system filesystems" from /etc/fstab.

Once this file exists it is considered a source of truth and will not be
modified.

This means if you need to do crazy things like modify the UUID or LABEL of your
root filesystem, you must update `/etc/.fstab.chef` to reflect these changes and
re-run Chef.

# Handling online disk repair
Chef will read a file `/var/chef/in_maintenance_disks` to determine any disks
currently being repaired online and skip mounting them. The format of the file
is one device, ala:

  /dev/sdd1
  /dev/sdq2

If this file has not been touched in 7 days it will be assumed to be stale and
will be removed. This is designed for online _repair_ not ignoring disks
permanently.
