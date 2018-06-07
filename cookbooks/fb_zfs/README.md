fb_zfs Cookbook
====================
This cookbook installs and configures support for the ZFS filesystem.

Requirements
------------

Attributes
----------
* node['fb_zfs']['enable_zed']
* node['fb_zfs']['import_on_boot']
* node['fb_zfs']['mount_on_boot']
* node['fb_zfs']['share_on_boot']

Usage
-----
Include `fb_zfs::zfsonlinux_repo` to enable the
[ZFS on Linux](http://zfsonlinux.org/debian.html) package repository. This is
provided as a separate recipe in case you prefer to mirror the packages locally
or use a different repository. Note that this repo only provides amd64 packages
for Debian Wheezy and Debian Jessie.

Include `fb_zfs::default` to install and configure ZFS. This will install the
necessary packages, which in turn will compile and load the ZFS kernel modules.
Note that this requires you to have kernel headers and a compiler available
(this recipe assumes that's already the case). By default we enable importing
and automounting of ZFS filesystems on boot and disable network sharing.
This can be controlled via the `node['fb_zfs']['import_on_boot']`,
`node['fb_zfs']['mount_on_boot']` and `node['fb_zfs']['share_on_boot']`
attributes. We also enable the ZED daemon by default, which can be disabled
with `node['fb_zfs']['enable_zed']`.
