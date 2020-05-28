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
* node['fb_grub']['force_both_efi_and_bios']
* node['fb_grub']['boot_disk']
* node['fb_grub']['manage_packages']
* node['fb_grub']['enable_bls']
* node['fb_grub']['users'][$USER]['password']
* node['fb_grub']['users'][$USER]['is_superuser']
* node['fb_grub']['require_auth_on_boot']

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

```ruby
node.default['fb_grub']['kernel_cmdline_args'] << 'crashkernel=128M'
```

Previous versions of this cookbook assumed the device containing grub is
enumerated as `hd0`. GRUB 2 can use labels or UUIDs. The option
`node['fb_grub']['use_labels']` allows users to opt into `search` behaviour
instead of hard coding the device.

If the device absolutely needs to be hardcoded, it can be overriden, as in:

```ruby
node.default['fb_grub']['boot_disk'] = 'hd1'
```

This cookbook will, by default, write to both the EFI and BIOS locations for
the grub config file. This can be problematic for cases were the EFI directory
may not exist so this behavior may be disabled by setting
`force_both_efi_and_bios` to false. This default is mostly an artifact of
Facebook history - you probably want to disable it.

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

### Boot Loader Specification support
Set `node['fb_grub']['enable_bls']` to `true` to enable automatic parsing and
menu entry generation from
[Boot Loader Specification](https://systemd.io/BOOT_LOADER_SPECIFICATION/)
compliant entries. This is needed e.g. to properly handle grubby-managed
entries on CentOS 8.

### User management
GRUB 2 can optionally restrict menu entries booting and editing. Add any user
definitions to `node['fb_grub']['users']`, e.g.:

```ruby
node.default['fb_grub']['users']['root'] = {
  # this is a plaintext password
  'password' => 'foo',
  'is_superuser' => true,
}

node.default['fb_grub']['users']['toor'] = {
  # this is an encryped password generated with grub2-mkpasswd-pbkdf2
  'password' => 'grub.pbkdf2.sha512.10000.A851ED187ADA6317A1E6E44045EA230FAA53B6B8BB0EF23CBE004FB298E78ECE3A0FEE37F732A5E10A96C5949A23A8D77FEF2A92C147E61D679B7028274113E1.3300DE40800F11EAD98F16F718728F8551821C156457B3EE8A4C815A859978E57EE5CF5D07F03833BAB7E2F17B6653031807E36BC94778A78E88D628C3C3E9A8',
}
```

By default, if any users are defined authentication will only be required for
editing menu entries. Set `node['fb_grub']['require_auth_on_boot']` to require
authentication also for booting.
