fb_hddtemp Cookbook
====================
The `fb_hddtemp` cookbook installs and configures hddtemp, an hard drive
temperature monitoring utility.

Requirements
------------

Attributes
----------
* node['fb_hddtemp']['enable']
* node['fb_hddtemp']['sysconfig']

Usage
-----
To install hddtemp include `fb_hddtemp`. Settings can be customized using the
`node['fb_hddtemp']['sysconfig']` attribute, please refer to the
[attributes file](attributes/default.rb) for the defaults, which attempt to
match upstreams distro default settings. The daemon is disabled by default, to
start it set `node['fb_hddtemp']['enable']` to true.
