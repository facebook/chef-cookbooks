fb_dracut Cookbook
====================
This cookbook installs and configures Dracut, the initramfs generator.

Requirements
------------

Attributes
----------
* node['fb_dracut']['conf']['add_dracutmodules']
* node['fb_dracut']['conf']['drivers']
* node['fb_dracut']['conf']['add_drivers']
* node['fb_dracut']['conf']['omit_drivers']
* node['fb_dracut']['conf']['filesystems']
* node['fb_dracut']['conf']['drivers_dir']
* node['fb_dracut']['conf']['fw_dir']
* node['fb_dracut']['conf']['do_strip']
* node['fb_dracut']['conf']['hostonly']
* node['fb_dracut']['conf']['mdadmconf']
* node['fb_dracut']['conf']['lvmconf']
* node['fb_dracut']['conf']['kernel_only']
* node['fb_dracut']['conf']['no_kernel']

Usage
-----
You can add any valid `dracut.conf` entry under `node['fb_dracut']['conf']`
If an attribute is set to `nil` or an empty list, the `dracut.conf` entry
for that attribute will not be written out. In this case the system
will use the default specified by dracut. See `man dracut.conf` on your
system to find out what that is.

The following are pre-initialized for you as noted:

* `node['fb_dracut']['conf']['add_dracutmodules']`
  Specify a list of dracut modules to add in the initramfs.
  (Should be array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['drivers']`
  Specify a list of kernel modules to exclusively include in the initramfs.
  The kernel modules have to be specified without the `.ko` suffix.
  (Should be array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['add_drivers']`
  Specify a list of kernel modules to add to the initramfs.
  The kernel modules have to be specified without the `.ko` suffix.
  (Should be array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['omit_drivers']`
  Specify a list of kernel modules to omit from the
  initramfs. The kernel modules have to be specified without the `.ko` suffix.
  Regular expressions are also allowed like `.*/fs/foo/.* .*/fs/bar/.*`.
  (Should be array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['filesystems']`
  Specify a list of kernel filesystem modules to exclusively
  include in the generic initramfs.  (Should be array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['drivers_dir']`
  Specify the directory, where to look for kernel modules.  (Should be a string)
  (default=empty)

* `node['fb_dracut']['conf']['fw_dir']`
  Specify a list of additional directories as strings, where to look for
  firmwares.  (Should be an array of strings)
  (default=empty)

* `node['fb_dracut']['conf']['do_strip']`
  Strip binaries in the initramfs.  (true|false|nil)
  (default=nil)

* `node['fb_dracut']['conf']['hostonly']`
  Host-Only mode: Install only what is needed for booting the local host
  instead of a generic host.  (true|false|nil)
  (default=true)

* `node['fb_dracut']['conf']['mdadmconf']`
  Include local `/etc/mdadm.conf`.  (true|false|nil)
  (default=true)

* `node['fb_dracut']['conf']['lvmconf']`
  Include local `/etc/lvm/lvm.conf`.  (true|false|nil)
  (default=true)

* `node['fb_dracut']['conf']['kernel_only']`
  Only install kernel drivers and firmware files.  (true|false|nil)
  (default=nil)

* `node['fb_dracut']['conf']['no_kernel']`
  Do not install kernel drivers and firmware files.  (true|false|nil)
  (default=nil)
