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

Usage
-----
This cookbook will configure GRUB 1 or GRUB 2 (defaults as appropriate for the
distro, override with `node['fb_grub']['version']`) to boot the kernels listed
in `node['fb_grub']['kernels']`. In most cases you'll probably want to write a
`ruby_block` to autodiscover these from the contents of `/boot` instead of 
statically populating it. If you need to parse or compare kernel versions as
part of this, you may find the `FB::Version` class in `fb_helpers` useful.
Note, that this cookbook will not install any kernel for you, it will just 
control the config.

This cookbook sets the GRUB timeout to 5 unless otherwise specified using
`node['fb_grub']['timeout']`. It defaults GRUB output to the system
console; this can be changed with `node['fb_grub']['terminal']`. If `serial` is
used for the terminal, set the values in `node['fb_grub']['serial']` as
appropriate (defaults to first serial port, 57600, 8-N-1).

Adding kernel command line args is accomplished by adding the argument as
an element to the `node['fb_grub']['kernel_cmdline_args']` array. 
Simply append the full text of the kernel command line arg as an element
to that array, ex.

    node.default['fb_grub']['kernel_cmdline_args'] << 'crashkernel=128M'

### tboot
This cookbook optionally supports enabling tboot. This is only supported for
GRUB 2 and is disabled by default. It can be controlled with the attribute
`node['fb_grub']['tboot']['enable']`. If desired, tboot logging output can be 
controlled with `node['fb_grub']['tboot']['logging']` (defaults to `memory`). 
If `serial` output is requested, it will reuse `node['fb_grub']['serial']` for 
its settings.
