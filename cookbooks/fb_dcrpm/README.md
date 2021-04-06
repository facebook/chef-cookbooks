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
* node['fb_dcrpm']['manage_packages']

Usage
-----
Include `fb_dcrpm` to install and manage `dcrpm`. If you'd like to manage
packages on your own, set `node['fb_dcrpm']['manage_packages']` to `false`.
