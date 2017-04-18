fb_p910d Cookbook
====================
This cookbook installs and configures p910nd, a lightweight print server.

Requirements
------------

Attributes
----------
* node['fb_p910nd']['number']
* node['fb_p910nd']['device']
* node['fb_p910nd']['bidirectional']
* node['fb_p910nd']['listen']

Usage
-----
Include `fb_p910nd` in your runlist to install p910nd and enable its service. By
default it will serve the printer at `/dev/usb/lp0`, which can be customized with
`node['fb_p910nd']['device']`, and assume it supports bidirectional printing, 
unless `node['fb_p910nd']['bidirectional']` is set to `false`. The daemon will
listen on all interfaces, unless `node['fb_p910nd']['listen']` is set to bind it
to a specific address. The listening port is always `910x`, where `x` is 
determined by `node['fb_p910nd']['number']`; this defaults to `0`, which means the
default listening port will be `9100`.
