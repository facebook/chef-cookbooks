fb_fstab coookbook
============
Support for full mount/fstab control.

Requirements
------------

Attributes
----------
* node['fb_fstab']['enable_remount']
* node['fb_fstab']['enable_unmount']
* node['fb_fstab']['allow_lazy_umount']
* node['fb_fstab']['type_normalization_map']
* node['fb_fstab']['ignorable_opts']
* node['fb_fstab']['umount_ignores']['devices']
* node['fb_fstab']['umount_ignores']['device_prefixes']
* node['fb_fstab']['umount_ignores']['types']
* node['fb_fstab']['umount_ignores']['mount_points']
* node['fb_fstab']['umount_ignores']['mount_point_prefixes']
* node['fb_fstab']['mounts'][$NAME]['device']
* node['fb_fstab']['mounts'][$NAME]['mount_point']
* node['fb_fstab']['mounts'][$NAME]['type']
* node['fb_fstab']['mounts'][$NAME]['opts']
* node['fb_fstab']['mounts'][$NAME]['dump']
* node['fb_fstab']['mounts'][$NAME]['pass']
* node['fb_fstab']['mounts'][$NAME]['only_if']
* node['fb_fstab']['mounts'][$NAME]['mp_owner']
* node['fb_fstab']['mounts'][$NAME]['mp_group']
* node['fb_fstab']['mounts'][$NAME]['mp_perms']
* node['fb_fstab']['mounts'][$NAME]['remount_with_umount']
* node['fb_fstab']['mounts'][$NAME]['enable_remount']
* node['fb_fstab']['mounts'][$NAME]['allow_mount_failure']
* node['fb_fstab']['mounts'][$NAME]['lock_file']

Usage
-----
`fb_fstab` will manage all mounts on a system. The primary mechanism for
interacting with it is through the `node['fb_fstab']['mounts']` hash which
allows you to specify mounts you want. For each entry in the hash, fb_fstab
will:
* populate `/etc/fstab` for you
* create the `mount_point` (but not parents) if it doesn't exist
* mount the filesystem

For "base mounts", i.e. the mounts that the machine came with from installation,
`fb_fstab`, will include them if a hint file is provided, or attempt to do an
educated guess - see "Base-OS Filesystems" below. Note that any entry in
`node['fb_fstab']['mounts']` with a matching `device` will override anything
found in "base mounts."

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

`node['fb_fstab']['allow_lazy_umount']` controls whether `fb_fstab` will try
lazy unmount with `umount -l` after failing to unmount normally. This is
intended to be used on systems that may have long-running jobs holding
filesystems busy. The default is `false`.

Lazy unmounts are inherently unsafe and should be used with caution. The
recommendation is to use this attribute only temporarily, to facilitate a mount
change and then turn in off. You should also refrain from using lazy unmounts
if you intend to mount a different filesystem under the same mountpoint. You
may end up in a situation when different processes see different devices
under the same filesystem path which becomes a troubleshooting nightmare at
best, and can easily blossom into a corruption / dataloss scenario.

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

The following are additional per-mount flags to `fb_fstab`:
  * `remount_with_umount` - by default, we remount with `mount -o remount`, but
                            if this is set, we will `umount` and `mount`
  * `lock_file` - a lock file to take when performing operations on this mount.
                  Useful for mounts that are also managed dynamically by others
                  on the system.
  * `enable_remount` - defaults to `false`, set to `true` if this FS should
                       be remounted
  * `mp_owner` - mountpoint owner
  * `mp_group` - mountpoint group owner
  * `mp_perms` - mountpoint permission mode
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
`mp_owner`, `mp_group`, and `mp_perms` in the hash as well. We will not enforce
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

Things that fail the `only_if` will not show up in `/etc/fstab` or be mounted.

### type_normalization_map
In order to allow filesystems that report differently from the kernel than what
we request there is a user-modifiable mapping fb_fstab uses to normalize the
types it compares. The default includes `'fuse.gluster' => 'gluster'`. You may
add other normalizations into this map. They are exact-string matches. Do not
overwrite the hash or you will lose the pre-populated entries, instead
add/modify:

```
node.default['fb_fstab']['fs_type_normalization_map']['fuse.gluster'] = 'gluster'
```

### ignorable_opts
Options that should be dropped from the mount-options when comparing for
equality. For example we drop 'nofail' because while we may want to set that in
`/etc/fstab`, it's never passed to the kernel and thus never in the visible
options for a mounted filesystem. The entries can either be strings or regexes.
Add to this list like so:

```
node.default['fb_fstab']['ignorable_opts'] << 'ignore_me'
```

### Base-OS filesystems
`fb_fstab` determines the base filesystems (root, boot, swap, etc.) that would
come from the original installation from `/etc/.fstab.chef`. It is recommended
you have your instalation system create this file (e.g in an Anaconda
post-script) with something like:

    grep -v '^#' /etc/fstab > /etc/.fstab.chef
    chmod 444 /etc/.fstab.chef

If such a file does not exist, `fb_fstab` will do it's best to generate one by
pulling things it believes are "system filesystems" from `/etc/fstab`.

Once this file exists it is considered a source of truth and will not be
modified.

This means if you need to do crazy things like modify the UUID or LABEL of your
root filesystem, you must either:
* Update `/etc/.fstab.chef` to reflect these changes and re-run Chef
* Populate `node['fb_fstab']['mounts']` with an entry that overrides that
  entry

### Handling online disk repair
Chef will read a file `/var/chef/in_maintenance_disks` to determine any disks
currently being repaired online and skip mounting them. The format of the file
is one device, ala:

  /dev/sdd1
  /dev/sdq2

If this file has not been touched in 7 days it will be assumed to be stale and
will be removed. This is designed for online _repair_ not ignoring disks
permanently.

