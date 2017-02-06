fb_grub Cookbook
====================
This cookbook will install the GRUB bootloader and generate a sane config for
it.

Requirements
------------

Attributes
----------
* node['fb_grub']['timeout']
* node['fb_grub']['kernel_cmdline_args']
* node['fb_grub']['kernels']
* node['fb_grub']['serial']['unit']
* node['fb_grub']['serial']['speed']
* node['fb_grub']['serial']['word']
* node['fb_grub']['serial']['parity']
* node['fb_grub']['serial']['stop']
* node['fb_grub']['tboot']['enable']
* node['fb_grub']['tboot']['logging']
* node['fb_grub']['terminal']
* node['fb_grub']['version']
* node['fb_grub']['use_labels']
* node['fb_grub']['boot_disk']
* node['fb_grub']['manage_packages']

Usage
-----
This cookbook will configure GRUB 1 or GRUB 2 (defaults as appropriate for the
distro, override with `node['fb_grub']['version']`) to boot the kernels listed
in `node['fb_grub']['kernels']`. In most cases you'll probably want to write a
`ruby_block` to autodiscover these from the contents of `/boot` instead of
statically populating it. If you need to parse or compare kernel versions as
part of this, you may find the `FB::Version` class in `fb_helpers` useful.
Note that this cookbook will not install a kernel for you, it will just
control the GRUB config. The cookbook will install and keep updated the 
appropriate GRUB packages; if you'd rather handle this somewhere else, set
`node['fb_grub']['manage_packages']` to `false`.

This cookbook sets the GRUB timeout to 5 unless otherwise specified using
`node['fb_grub']['timeout']`. It defaults GRUB output to the system
console; this can be changed with `node['fb_grub']['terminal']`. If `serial` is
used for the terminal, set the values in `node['fb_grub']['serial']` as
appropriate (defaults to first serial port, 57600, 8-N-1).

Adding kernel command line args is accomplished by adding the argument as
an element to the `node['fb_grub']['kernel_cmdline_args']` array.
Simply append the full text of the kernel command line arg as an element
to that array, e.g.:

    node.default['fb_grub']['kernel_cmdline_args'] << 'crashkernel=128M'

Previous versions of this cookbook assumed the device containing grub is
enumerated as `hd0`. GRUB 2 can use labels or UUIDs. The option
`node['fb_grub']['use_labels']` allows users to opt into `search` behaviour
instead of hard coding the device.

If the device absolutely needs to be hardcoded, it can be overriden, as in:

    node.default['fb_grub']['boot_disk'] = 'hd1'

### tboot
This cookbook optionally supports enabling tboot. This is only supported for
GRUB 2 and is disabled by default. It can be controlled with the attribute
`node['fb_grub']['tboot']['enable']`. If desired, tboot logging output can be
controlled with `node['fb_grub']['tboot']['logging']` (defaults to `memory`).
If `serial` output is requested, it will reuse `node['fb_grub']['serial']` for
its settings.

When tboot is enabled, two menu entries are created for each kernel: one with
tboot as the MLE before launching the kernel, and one launching the kernel
directly without tboot.

NOTE: tboot is not compatible with Secure Boot enabled. Please see the RedHat
bug report for more information: https://bugzilla.redhat.com/show_bug.cgi?id=1318667
