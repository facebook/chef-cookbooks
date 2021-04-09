fb_dcrpm Cookbook
=================
This cookbook installs and manages
[dcrpm](https://github.com/facebookincubator/dcrpm),
a tool to detect and correct common issues around RPM database corruption.

Requirements
------------
RPM-based system, like CentOS.

Attributes
----------
* node['fb_dcrpm']['enable_periodic_task']
* node['fb_dcrpm']['manage_packages']

Usage
-----
Include `fb_dcrpm` to install and manage `dcrpm`. If you'd like to manage
packages on your own, set `node['fb_dcrpm']['manage_packages']` to `false`. By
default, `fb_dcrpm` will setup a periodic task to run `dcrpm` every hour. To
disable this, set `node['fb_dcrpm']['enable_periodic_task']` to `false`.
