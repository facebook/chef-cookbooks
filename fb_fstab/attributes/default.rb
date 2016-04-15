# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_fstab'] = {
  'mounts' => {},
  'enable_remount' => false,
  'enable_unmount' => false,
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
      'swap',
      'usbfs',
      'binfmt_misc',
      'sysfs',
      'proc',
      # sub-cgroup mounts will have this type. See comment above.
      'cgroup',
    ],
    'mount_points' => [
      # Core OS stuff to never umount...
      '/run',
      # Debian-isms
      '/run/shm',
      '/run/lock',
      '/run/user',
      '/sys/fs/pstore',
      '/sys/kernel/debug',
      '/sys/kernel/security',
      '/sys/fs/fuse/connections',
    ],
  },
}
