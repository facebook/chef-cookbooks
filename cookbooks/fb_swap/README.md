fb_swap Cookbook
====================
This cookbook enables or disables swap.

Requirements
------------
This cookbook assumes the machine will have either zero or one swap partition
defined in `/etc/fstab`. It does not support swap files and more than one swap 
partition. 

Attributes
----------
* node['fb_swap']['enabled']
* node['fb_swap']['size']
* node['fb_swap']['enable_encryption']

Usage
-----
You can disable swap with:

    node.default['fb_swap']['enabled'] = false

or you can enable swap if its off like this:

    node.default['fb_swap']['enabled'] = true

The default is `true`. You can also optionally define the size in kb of the
swap device to use with `node['fb_swap']['size']`. This defaults to `nil`,
which disables the resizing logic. The Chef run will fail if it's set to a value
smaller than 1024 (i.e. 1 MB), which is assumed to be a typo (if you really
want a swap device this small consider disabling swap altogether). Note that
the value set is passed directly to `mkswap`, and should be no larger than the
size of the actual block device; to prevent accidental destruction of data we
only allow reducing the size of a swap device, not making it larger. The resize
operation triggers a swap disable / enable, which could potentially trigger the
OOM killer if the machine is under memory pressure.


You can enable encrypted swap with:

    node.default['fb_swap']['enable_encryption'] = true

or you can turn it off like this:

    node.default['fb_swap']['enable_encryption'] = false

The default is `false`. We use dm-crypt/LUKS for the encryption. For details see
cryptsetup(8).
