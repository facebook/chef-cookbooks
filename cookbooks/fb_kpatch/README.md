fb_kpatch Cookbook
====================
This cookbook installs and configures kpatch.

Requirements
------------

Attributes
----------
* node['fb_kpatch']['enable']

Usage
-----
Include `fb_kpatch::default` to install kpatch. The daemon is enabled and
started by default; this can be controlled with `node['fb_kpatch']['enable']`.
