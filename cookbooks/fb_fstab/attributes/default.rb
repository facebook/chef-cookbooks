# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_fstab'] = {
  'mounts' => {},
  'enable_remount' => false,
  'enable_unmount' => false,
  'allow_lazy_umount' => false,
  'umount_ignores' => {
    'devices' => [
      # Various virtualFSes
      'rootfs',
      'debugfs',
      'udev',
      'devpts',
      'systemd',
      'devtmpfs',
      'devpts',
      'sunrpc',
      'nfsd',
      # The primary way we except cgroup mounts is via the 'cgroup' fstype in
      # the 'types' array below. Types is always better than device names which
      # are unreliably gathered because of Ohai. However, the root is always a
      # tmpfs and not a 'cgroup' FS, so we have to exempt that mount too... on
      # RH that tmpfs has a device name of 'cgroup_root' and on Ubuntu it's
      # 'cgroups'
      'cgroup_root',
      'cgroups',
      'rpc_pipefs',
      # You get this on some boxes with bad mtabs...
      '/dev/root',
      '/dev',
    ],
    # use this one with caution!
    'device_prefixes' => [],
    'types' => [
      # Core OS stuff to never umount...
      'autofs',
      'binfmt_misc',
      'cgroup', # sub-cgroup mounts will have this type. See comment above.
      'configfs',
      'efivarfs',
      'hugetlbfs', # hugepages
      'mqueue', # POSIX queues
      'proc',
      'swap',
      'sysfs',
      'tracefs', # kernel debugging
      'usbfs',
    ],
    'mount_points' => [
      # Core OS stuff to never umount...
      '/dev/shm',
      '/run',
      '/sys/fs/cgroup',
      '/sys/fs/selinux',
      # Debian-isms
      '/run/shm',
      '/run/lock',
      '/sys/fs/pstore',
      '/sys/kernel/debug',
      '/sys/kernel/security',
      '/sys/fs/fuse/connections',
    ],
    'mount_point_prefixes' => [
      '/run/user',
    ],
  },
  'type_normalization_map' => {
    # Gluster is mounted as '-t gluster', but shows up as 'fuse.gluster'
    # ... is this true for all FUSE FSes? Dunno...
    'fuse.gluster' => 'gluster',
  },
  'ignorable_opts' => [
    # seclabel is something the kernel hands you to signify if it's on,
    # not an option you pass in, and thus shouldn't be part of the comparison
    'seclabel',
    # nofail is an option you pass in to fstab, but not an option
    # that gets passed to the kernel, therefore you won't see it in the mount
    # options and can't use it in the comparison
    'nofail',
    # NFS sometimes automatically adds addr=<server_ip> here automagically,
    # which doesn't affect the mount, so don't compare it.
    /^(mount)?(addr|port|proto)=.*/,
  ],
}
