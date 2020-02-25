fb_util_linux Cookbook
==================
This cookbook installs and manages util-linux.

Requirements
------------
CentOS

Attributes
----------
* node['fb_util_linux']['enable_fstrim']
* node['fb_util_linux']['manage_packages']

Usage
-----
This cookbook will install and manage util-linux. It will install the necessary
packages by default; set `node['fb_util_linux']['manage_packages']` to `false`
to opt out. By default global periodic fstrim is disabled -- it can be enabled
by setting `node['fb_util_linux']['enable_fstrim']` to `true`.
