fb_smartmon Cookbook
====================
This cookbook manages the package `smartmontools` and `smartctl`
as well as the server `smartd`

Requirements
------------

Attributes
----------
* node['fb_smartmon']['enable']
* node['fb_smartmon']['config'][$DIRECTIVE][$CONFIG]

Usage
-----
By default this cookbook will install the `smartmontools` package
which allows the `smartctl` command to be used.

By default `node['fb_smartmon']['enable']` is set to false which
disables the `smartd` service

Setting `node['fb_smartmon']['enable']` to `true` will enable the
`smartd` service

`node['fb_smartmon']['config'][$DIRECTIVE][$CONFIG]` controls
the `/etc/smartd.conf` config. The `$DIRECTIVE` can be a device
device such as `/dev/sda` - or a command such as `DEVICESCAN`
or `DEFAULT`. `$CONFIG` can be used to specify an options the
directive takes (see smartd.conf man pages).
