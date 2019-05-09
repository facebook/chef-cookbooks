fb_swap Cookbook
====================
This cookbook manages swap on Linux.

Requirements
------------
This cookbook assumes the machine will have either zero or one swap partitions
on disk. It uses `fb_fstab` API to define the swap device and/or file and uses
systemd's systemd-fstab-generator to create unit files. As there are resources
to run before and after `fb_fstab` the cookbook should be included in this way:

```
include_recipe 'fb_swap::before_fb_fstab'
include_recipe 'fb_fstab'
include_recipe 'fb_swap::after_fb_fstab'
```

Attributes
----------
* node['fb_swap']['enabled']
* node['fb_swap']['size']
* node['fb_swap']['swapoff_allowed_because']
* node['fb_swap']['filesystem']
* node['fb_swap']['strict']

Usage
-----
WARNING: This code has been refactored significantly. The new behaviour is in
before_fb_fstab.rb and after_fb_fstab.rb respectively. Subsequent updates will
eventually remove default.rb and the old limitations.

You can disable swap with:

```
node.default['fb_swap']['enabled'] = false
```

or you can enable swap if its off like this:

```
node.default['fb_swap']['enabled'] = true
```

The default is `true`. You can also optionally define the size in kb of the
swap device to use with `node['fb_swap']['size']`. This defaults to `nil`,
which disables the resizing logic in the old version. In the new version it
means use 100% of an existing swap device. The Chef run will fail if it's set
to a value smaller than 1024 (i.e. 1 MB), which is assumed to be a typo. If you
really want a swap device this small consider disabling swap altogether. The
resize operation triggers a swap disable / enable, which could potentially
trigger the OOM killer if the machine is under memory pressure.

For the new version:

Use:

```
node.default['fb_swap']['swapoff_allowed_because'] = 'reason'
```

If you are in a state where OOM is unlikely (e.g. during initial server setup)
and you can tolerate swap being evicted and disabled for a moment. The
attribute defaults to nil which disables the ability to use swapoff/resizing.

This cookbook uses node.default['fb_fstab']['exclude_base_swap'] to exclude any
'base filesystem' mounts defined in /etc/fstab.

This cookbook defines a helper method to determine whether extending swap is a
good idea: FB::FbSwap.swap_file_possible?(node). It uses
node['fb_swap']['filesystem'] to base it's decisions on. This defaults to the
root filesystem ('/'). When this is set to a different filesystem, swap
partition is turned off and only the swap file is used.

The default configuration has swap enabled, using 100% of a swap device. If
there is no swap partition this will raise a runtime error. To demote the error
to a warning, use:

```
node.default['fb_swap']['strict'] = false
```

* btrfs root filesystem is not supported until https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=ed46ff3d423780fa5173b38a844bf0fdb210a2a7
* If any device(s) belonging to the root filesystem are rotational, using a
  swap file is not recommended.
