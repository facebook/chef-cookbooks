fb_storage Cookbook
===================
Provision and manage storage devices and partitions.

Requirements
------------

Attributes
----------
* node['fb_storage']['format']['firstboot_converge']
* node['fb_storage']['format']['firstboot_eraseall']
* node['fb_storage']['format']['hotswap']
* node['fb_storage']['format']['missing_filesystem_or_partition']
* node['fb_storage']['format']['mismatched_filesystem_or_partition']
* node['fb_storage']['format']['mismatched_filesystem_only']
* node['fb_storage']['tuning']['scheduler']
* node['fb_storage']['tuning']['queue_depth']
* node['fb_storage']['tuning']['discard_max_bytes']
* node['fb_storage']['tuning']['over_provisioning']
* node['fb_storage']['tuning']['over_provisioning_mapping']
* node['fb_storage']['tuning']['max_sectors_kb']
* node['fb_storage']['fstab_use_labels']
* node['fb_storage']['manage_mdadm_conf']
* node['fb_storage']['stop_and_zero_mdadm_for_format']
* node['fb_storage']['hybrid_xfs_use_helper']
* node['fb_storage']['format_options']
* node['fb_storage']['_num_non_root_devices']
* node['fb_storage']['arrays']
* node['fb_storage']['devices']
* node['fb_storage']['_handlers']
* node['fb_storage']['_clowntown_device_order_method']
* node['fb_storage']['_clowntown_override_file_method']

Usage
-----
The storage API is a generic API designed to allow you to describe storage
layout in a vendor-agnostic way and have it work across various backends such
as LSI flash, FIO flash, NVME flash, JBOD, etc. including using software RAID.

**NOTE**: This API explicitly excludes whatever device the root filesystem is
on.

### Enabling

The storage API will only run if `node['fb_storage']['devices']` is not empty.

### Convergence Rules

Unlike most things, service owners need more fine-grained control over when Chef
is allowed to converge storage. To that end, this API provides the following
'format' options:

* `firstboot_converge` (true)
* `firstboot_eraseall` (false)
* `hotswap` (true)
* `missing_filesystem_or_partition` (false)
* `mismatched_filesystem_or_partition` (false)
* `mismatched_filesystem_only` (false)

To change one, simply:

```
node.default['fb_storage']['format']['firstboot_eraseall'] = true
```

The defaults are as above. These have the following meaning:

* `firstboot_converge` - Any non-matching storage (excluding that holding the
  root filesystem) may be converged on `firstboot_tier`.
* `firstboot_eraseall` - Erase all storage (excluding that holding the
  root filesystem) on `firstboot_tier`.
* `hotswap` - Erase disks external automation has told us it replaced. This is
  designed to support disk hotswap.
* `missing_filesystem_or_partition` - Any missing partition tables may be
  created, and any missing filesystems may be created on **any** Chef run,
  including live systems **in production**.
* `mismatched_filesystem_or_partition` - Any partition tables that are not
  correct (read: mis-matched number of partitions) or any filesystems that are
  not correct (read: wrong FS type) may be corrected on **any** Chef run,
  including live systems **in production**. **You almost certainly do not want
  this. It is dangerous!**
  **NOTE**: Implies `missing_filesystem_or_partition`.
* `mismatched_filesystem_only` - Any filesystems of the wrong type may be
  corrected on **any** Chef run, including live systems **in production**.

### Migration overrides

There are a handful of files you can touch to force converging your storage
outside of the permissions provided in your recipe to aid in migration and
testing of diffs. **NOTE**: These bypass the entire permissions model, so
be careful.

* `/var/chef/storage_force_converge_all` - This file will cause the Storage API
  to act as if we are in firstboot and `firstboot_converge` is set in your
  recipe - i.e. it will converge any storage it believes it needs to,
  destructively. Once it converges, it will remove the file.
* `/var/chef/storage_force_erase_all` - This file will cause the Storage API
  to act as if we are in firstboot and `firstboot_eraseall` is set in your
  recipe - i.e. it will erase *all* of your non-root devices and then set them
  back up. Once it converges, it will remove the file.

For additional safety, you can define a check method in
`node['fb_storage']['_clowntown_override_file_method']`
that will be invoked whenever override files are evaluated.

You can also use files in `/var/chef/hotswap_replaced_disks/` as described in
`Disk Replacement` below to test individual disk setup. However, note that this
has limited ability to track which RAID arrays those disks are members of. It
can add them back to arrays that exist, and it will rebuild and reformat RAID0
arrays, but that's the extent of its ability.

### Defining storage layout

The `devices` array is mapped to a list of devices like so:

```
node.default['fb_storage']['devices'] = [
  # fioa or sdb
  {
    'partitions' => [
      # fioa1 or sdb1
      {
        'type' => 'xfs',
        'mount_point' => '/data/fa',
        'opts' => 'rw,noatime,allocsize=32m,discard',
        'pass' => 2,
        'enable_remount' => true,
      },
    ],
  },
]
```

`devices` and the `partitions` entry in each device are an array to make it
clear they are ordered. They will be applied to storage in the order of the
array, so do not jam things in the middle.

The above config would build a single partition on the first non-root device
(/dev/fioa for FIO, /dev/sdb for LSI, etc.), format it with xfs and pass the
following whitelisted options to `fb_fstab` for mounting:
* `type`
* `mount_point`
* `opts`
* `pass`
* `enable_remount`
* `allow_mount_failure`

Please see `fb_fstab` documentation for further explanation of these fields.

You can set a *device* to look like `{'_skip' => true}` to skip a given device
(say if you have some hardware that has two flash cards, but only want to use
one).

**NOTE**: If you have more than one non-root device, see Ordering below.

The special option `_no_mount` can be passed to tell Storage not to pass a given
partition's information to `fb_fstab` in order to prevent mounting. This is
often used when that filesystem is being exported over `NBD`.

The special option `_no_mkfs` can be passed to tell Storage not to create a
filesystem on that partition. This is often used when the device is being
exported over a block protocol such as `NBD`.

Multiple partitions can be defined by specifying a `partition_start` and
`partition_end` in each:

```
node.default['fb_storage']['devices'] = [
  # fioa or sdb
  {
    'partitions' => [
      # fioa1 or sdb1
      {
        'partition_start' => '0%',
        'partition_end' => '50%',
        'type' => 'xfs',
        'mount_point' => '/data/fa1',
        'opts' => 'rw,noatime,allocsize=32m,discard',
        'pass' => 2,
        'enable_remount' => true,
      },
      # fioa2 or sdb2
      {
        'partition_start' => '50%',
        'partition_end' => '100%',
        'type' => 'xfs',
        'mount_point' => '/data/fa2',
        'opts' => 'rw,noatime,allocsize=32m,discard',
        'pass' => 2,
        'enable_remount' => true,
      },
    ],
  },
]
```

The partition positioning parameters support anything `parted` understands,
though we attempt to do some basic validation of it.

There is a special parameter that may be specified inside a device:
`whole_device`. If this is true the device will be formatted instead of a
partition. **This is strongly discouraged** but provided for backwards
compatibility.

For the purposes of migration, we provide a method
`FB::Storage.mountpoint_uses_whole_device(node, mountpount)` which you
can use to set `whole_device` only on existing systems on existing mounts, so that
it will move to a partition on re-imaging, but not complain about mis-matched
partitions until then.

You can also add `label` to any partition hash to add a filesystem label -
though by default it will always label the filesystem with its mountpoint.

You can also add `part_name` to any partition hash to add a name to the partition
created via parted; default is not named.

### Ordering

We assemble the list, and it is sorted as follows:
* First, locally-attached disks (including flash, *NOT* including disagg disks)
  in block-device-sorting order as explained below
* Then, disaggregate-attached disks in slot order (according to fbjbod)

Our locally-attached disks are sorted as follows:
* Length-alpha-numeric of prefix (`sd`, `fioa`, `nvme`, etc.)
* SCSI address of device
* Length-alpha-numeric of device letters/numbers (usually `a`, `b`, `aa`, etc.,
  but for some devices `0`, `1`, `2`)

We take into account `in_maintenance_disks` (see `fb_fstab`) so that disks in
repair will not skew the mapping.

This means if you have one FIO and one LSI card, `/dev/sdb` mapps to the first
entry in `devices` while `/dev/fioa` maps to the second.

To make the ordering clear, here's an visual:

```
--------------
       |------
       | | sdb (6:0:0:0)  \
       | | sdg (6:1:0:0)   \
       | | sdd (6:2:0:0)    } locally attached disks in SCSI slot order
       | | sde (6:3:0:0)   /   (note here sdg replaced and sdc later)
       | | sdf (6:4:0:0)  /
sd     |------
       | | sdh  \
       | | sdi   } locally attached disks not found in `lsscsi`
       | | sdj  /
       |------
--------------
       |------
       | |           (FIO doesn't appear on SCSI bus, no drives here)
fio    |------
       | | fioa   \
       | | fiob   /  locally attached disks not found in `lsscsi`
       |------
--------------
       |------
       | |           (NVME doesn't appear on SCSI bus, no drives here)
nvme   |------
       | | nvme0n1   \
       | | nvme1n1   /  locally attached disks not found in `lsscsi`
       |------
--------------
       |------
       | | sdk (slot 1)   \
fbjbod | | sdl (slot 2)    \
       | | sdo (slot 3)     } fbjbod (knox/bc trays) in slot order
       | | sdn (slot 4)    /   per fbjbod CLI
       | | sdm (slot 5)   /
       |------
---------
```

### Format options

`node['fb_storage']['format_options']` are options to pass to the relevant
`mkfs`. As you might want to format more than one disks, with more than one
kind of filesystems, it accepts several formats:
* String: just pass it to `mkfs`
* Hash: pass the entry corresponding to the filesystem type being formatted

#### fstab_use_labels

The `node['fb_storage']['fstab_use_labels']` option will control
whether or not `fb_fstab`'s information is populated with device names or
labels. The default is currently `true`.

#### manage_mdadm_conf

If you have specified arrays, then Storage will generate an `/etc/mdadm.conf`
for you based on the output of `mdadm --detail --scan`. You can disable that by
setting this option to `false`.

#### stop_and_zero_mdadm_for_format

If Chef has been instructed to format a device currently in an mdraid array it
will attempt to remove that device from the array. By default, if that removal
fails then we will fail the Chef run and the device will remain untouched.
Removal commonly fails when devices are members of a raid0.

Setting this value to `true` will allow Chef to stop the array and zero the
mdraid superblock on the device.

Defaults to `false`.

### Tuning

We support several tuning options which will be set (via sysfs) for all eligible
storage controlled by this API: `queue_depth`, `scheduler`,
`discard_max_bytes`, and `max_sectors_kb`.

Note: `max_sectors_kb` sets the maximum IO sizes to the minimum of the device's
`max_hw_sectors_kb` and the one provided.

The `over_provisioning` and `over_provisioning_mapping` attributes are provided
for storage handlers to manage over provisioning, but are currently not used
by `fb_storage` itself.

### Software Raid

The Storage API supports setting up software RAID using Linux's mdraid. To do
this you populate the `array` structure with information about the arrays you
want to build and then use the `devices` structure from above simply to tie
physical devices to an array. For example, let's say you want to stripe two
flash cards:

```
node.default['fb_storage']['arrays'] = [
  {
    'type' => 'xfs',
    'mount_point' => '/data/fa',
    'opts' => 'rw,noatime',
    'pass' => 2,
    'enable_remount' => true,
    'raid_level' => 0,
  }
]
node.default['fb_storage']['devices'] = [
  {
    'partitions' => [
      {
        # maps this device to the 0th storage array (above)
        '_swraid_array' => 0,
      },
    ],
  },
  {
    'partitions' => [
      {
        # maps this device to the 0th storage array (above)
        '_swraid_array' => 0,
      },
    ],
  },
]
```

This will create a single partition on each flash card that consumes the entire
device and then make a RAID0 array out of them, which will then be formatted as
'xfs' and mounted as `/data`.

You can use `_swraid_array_journal` if you want the array's journal on a
separate device. This is generally only done on Sunrise Peak machines to put the
journal on the supercapacitor-backed DRAM device. It works identically to
`_swraid_array` - just pass it the integer of the array it belongs to.

The `_no_mount` option also works here. In addition you can specify
`raid_stripe_size` to specify the striping width (i.e. chunk size).

You may also specify additional options to be passed to the 'mdadm create'
command using the 'create_options' option, e.g.

```
    'create_options' => '--assume-clean --bitmap=none --layout=o2',
```

NOTE: `whole_device` is incompatible with `_swraid_array` and they may not be
used together. Arrays must be on top of partition devices.

It's worth noting the permission model setup by the Storage API is not quite
clear when working with arrays. It works like this:

* If we were given permission to touch disks (for any reason) and those disks
  are missing from an otherwise-correct arrays, we will add them to those arrays
* If we are given permission to touch every single disk in an array and that
  array needs work, we will do said work.
* If we were given `firstboot_converge` or `firstboot_eraseall` and we are in
  firstboot, we will converge or re-build all arrays requested, even if that
  will be destructive (as those permissions imply)
* If we are given `mismatched_filesystem_or_partition`, the most dangerous and
  permissive permission, we will converge arrays including destroying and
  rebuilding if necessary (even on live systems)
* If we are given `missing_filesystem_or_partitions` we will build missing
  arrays as long as they won't effect any mounted filesystem. We will also
  add devices to missing arrays, assuming they are not mounted.

This will still work with hotswap: automation-replaced disks will always be
acted upon when we have the `hotswap` permission, which, will cause the
drive to be re-added to the array. However, with RAID0, this is meaningless,
so we require ability to destroy an array to rebuild it (i.e. we treat it as a
'mismatched' array).

One other note on re-adding drives: not all code that pre-dates the Storage API
used optimal partition layout, and so if we are told to add a device to an
existing device without a proper layout, it can fail. This case is not handled,
at all. Chef will fail and manual intervention is needed. The only time we can
hit this is:
  * The array was built with the old mdfio or some other chunk of code
  * Hot swap is enabled, and a card is replaced by external automation and we
    are told about that.
This should be exceedingly rare.

### Hybrid XFS

Hybrid XFS is handled as if it were an array. This allows us to use all the same
logic for tracking dependent filesystems. Since hybrid XFS works very similarly
to SW RAID arrays with a separate journal device, the model maps nicely.

Like with swraid arrays you tie physical devices to their virtual device, but
instead of using `_swraid_array` and `_swraid_array_journal`, you use
`_xfs_rt_data` and `_xfs_rt_metadata`.

A helper function `FB::Storage.hybrid_xfs_md_size` is available to
help you. Here's an example usage for setting up 8 Hybrid XFS filesystems on a
machine with 1 flash card and 8 data disks:

```
# Setup our extra XFS options
node.default['fb_storage']['format_options'] =
  '-i size=2048 -s size=4096'
number_fses = 8

# Setup the virtual devices
node.default['fb_storage']['arrays'] = number_fses.times.map do |i|
  {
    'mount_point' => "/mnt/d#{i}",
    'type' => 'xfs',
    'raid_level' => 'hybrid_xfs',
  }
end

# Determine how big the MD devices need to be
# args:
#  - 0: index of the drive (in the same order as the devices array)
#       we want to be the metadata device (usually a flash device)
#  - 8: number of filesystems we want
md_size = FB::Storage.hybrid_xfs_md_part_size(node, 0, number_fses)

# Create all of our devices
node.default['fb_storage']['devices'] = [
  {
    # one partition on the flash drive per FS
    'partitions' => number_fses.times.map do |i|
      start = (md_size * i)
      {
        '_xfs_rt_metadata' => i,
        'partition_start' => start == 0 ? "0%" : "#{start}MiB",
        'partition_end' => "#{start + md_size - 1}MiB",
      }
    end,
  }
] + number_fses.times.map do |i|
    # One device per FS...
    {
      # first a rescue partition, same size as the MD - just an empty
      # place to `dd` to if we need to save the MD from a dying metadata
      # (flash) device.
      'partitions' => [
        {
          '_xfs_rt_rescue' => i,
          'partition_start' => "0%",
          # add one MB to the size to ensure we have enough room, in case
          # there is futzing with parted's optimization movements
          'partition_end' => "#{md_size + 1}MiB",
        },
        {
          '_xfs_rt_data' => i,
          'partition_start' => "#{md_size + 2}MiB",
          'partition_end' => "100%",
        },
      ],
    }
  end
```

Note that if `node['fb_storage']['hybrid_xfs_use_helper']` is set to
`true` (the default), then instead of Chef statically putting the `rtdev=`
argument in the mount options in `/etc/fstab`, we will instead set the
filesystem to `rtxfs` which will trigger a mount-helper (/sbin/mount.rtxfs,
dropped off by this cookbook), which will look for a partition with a
`partition name` of the filesystem in question and use that as the rtdev.

#### `FB::Storage.hybrid_xfs_md_part_size`

This method takes three arguments and returns the size each partition should be
in MiB.

The arguments are:
* `node`: The node object
* `index`: The index of the device (same ordering as the `devices` array) that
  will be used for metadata
* `number_fses`: The number of filesystmes we want to make

Note that `number_fses` is optional and will default to the total number of
available data devices (not including root disk) on the system - 1 (the device
used for metadata). In other words if you have a root drive, a flash card, and 8
other disks, the default for this value is 8.

#### Custom extsize

By default Chef will format Hybrid XFS arrays with a 256k (262144 byte) extent
size. This can be overriden by setting the 'extsize' value within the array.
For example:

```
node.default['fb_storage']['arrays'] = [
  {
    'mount_point' => "/mnt/d#{i}",
    'type' => 'xfs',
    'raid_level' => 'hybrid_xfs',
    'extsize' => 1069056  # 1044KiB
  }
]
```

This will be passed to the mkfx.xfs command. Chef Storage API will not treat a
disk with the wrong extsize as out of spec.

### Disk Replacement

External automation can touch a file in `/var/chef/hotswap_replaced_disks` to
signal to Chef a disk needs to be provisioned outside of normal host
provisioning. The file is the name of the device without partitions, and Chef
will remove the file once it's successfully able to partition and format the
disk. Example filenames:
`/var/chef/hotswap_replaced_disks/nvme0n1`,
`/var/chef/hotswap_replaced_disks/sdb`.

### Storage handlers
Device-level logic is implemented as Storage Handlers in `fb_storage`. Handlers
are subclasses of `FB::Storage::Handler` and must implement the handler
interface. Handler classes listed in `node['fb_storage']['_handlers']` will be
queried in order, and the first one to match for a given device will be used.

By default `fb_storage` provides handlers for FusionIO, MD (software RAID) and
JBOD devices.

### WARNINGS

Due to the nature of matching the number of storage devices to the number of
array entries, we recommend you assign the entire `devices` array in a single
recipe.

If you plan to reformat live storage (say, using `mismatched_filesystem_only`),
we recommend you shard that on, and set it back to `false` when done.

If you make changes to a device layout (more/less partitions), it will be
repartitioned (if allowed by the `format` partitions), and all data will be thus
wiped.

### Determining the number of devices on a system

`node['fb_storage']['_num_non_root_devices']` will tell you how many
devices you have available to you, not including the root device. You may read
this at anytime to make decisions. **Do not write to this**!

### Custom device ordering

Chef Storage API supports arbitrary ordering of devices. To use create a method
that will return an array of logical devices in the desired order. This should
be the entry in /dev/, not inclusive of /dev/. So, `sdb`, not `/dev/sdb`.
Assign this method to the
`node['fb_storage']['_clowntown_device_order_method']` attribute.

This is useful for hosts that have been provisioned by earlier systems and that
cannot be easily converged to Chef's built-in disk ordering.

This ordering will only be written during the `firstboot_tier` phase or when
the `/var/chef/storage_force_write_custom_disk_order` file is present. Use this
file to aid with development or to trigger a mass write of a fleet's ordering
files.

Chef will automatically remove the
`/var/chef/storage_force_write_custom_disk_order` file, even if the ordering
method throws an exception.

NOTE WELL!!!! You should ensure you **only** populate this method on machines
that *need* it, not blanketly. This way new machines will converge on the
proper ordering.

MISUSE OF THIS FEATURE CAN CAUSE DATA LOSS!!! TEST WELL!!!
