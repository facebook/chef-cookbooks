fb_kernel Cookbook
==================
Manage installed kernels and their configurations on the system.

Requirements
------------

Attributes
----------
* node['fb_kernel']['kernels'][$KERNEL][$KEY][$VAL]
* node['fb_kernel']['manage_bls_configs']
* node['fb_kernel']['manage_packages']
* node['fb_kernel']['boot_path']
* node['fb_kernel']['want_devel']
* node['fb_kernel']['install_options']
* node['fb_kernel']['remove_options']

Usage
-----
Include `fb_kernel` in your runlist to manage kernels on your system. Populate
`node['fb_kernel']['kernels']` with the desired kernels, e.g.:

```ruby
node.default['fb_kernel']['kernels']['my kernel'] = {
  'version' => '4.16.18-196',
  'linux' => '/vmlinuz-4.16.18-196',
  'id' => 'centos-kgdivtcnc-4.16.18-196',
  'initrd' => '/initramfs-4.16.18-196',
  'options' => 'root=/dev/sda1',
}
```

All values are optional, and will be autopopulated based on the key, which
should match the version in that case. For example:

```ruby
node.default['fb_kernel']['kernels']['4.16.18-196'] = {}
```

Paths for `linux` and `initrd` are related to `node['fb_kernel']['boot_path']`
which defaults to `/boot`. If `options` is not specified, it will default to
`$kernelopts` (i.e. to the bootloader default options).

### BLS Configs
By default `fb_kernel` will generate BLS configs for the desired kernels on
supported systems. This can be disabled by setting
`node['fb_kernel']['manage_bls_configs']` to `false`. Configs will be rendered
under `#{node['fb_kernel']['boot_path']}/loader/entries` in accordance with
the Bootloader Specification. Please refer to the
[upstream documentation](https://systemd.io/BOOT_LOADER_SPECIFICATION/)
for more details on the config format and usage.

### Package management
By default `fb_kernel` will manage installed kernels. This can be disabled by
setting `node['fb_kernel']['manage_packages']` to `false`. Packages for
desired kernels will be installed if missing, and other kernel packages will
be removed. If `node['fb_kernel']['want_devel']` is `true`, the corresponding
`kernel-devel` packages will also be installed. Two additional attributes are
provided to pass custom options during package install and removal. This can
be useful, for example, if kernel packages are stored in dedicated repos that
are not normally available in the system configuration.
