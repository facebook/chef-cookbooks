fb_e2fsprogs Cookbook
=====================
This cookbook installs and configures e2fsprogs.

Requirements
------------

Attributes
----------
* node['fb_e2fsprogs']['manage_packages']
* node['fb_e2fsprogs']['e2fsck']
* node['fb_e2fsprogs']['mke2fs']

Usage
-----
Include `fb_e2fsprogs` to install and manage e2fsprogs. You can set the
`node['fb_e2fsprogs']['manage_packages']` attriubute to `false` if you'd like
to manage package install on your own.

Set `node['fb_e2fsprogs']['e2fsck]` and node[`e2fsprogs']['mke2fs']` to
customize e2fsprogs config.
