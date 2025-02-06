fb_kpatch Cookbook
==================
This cookbook installs and configures kpatch.

Requirements
------------

Attributes
----------
* node['fb_kpatch']['enable']
* node['fb_kpatch']['manage_packages']

Usage
-----
Include `fb_kpatch::default` to install kpatch. The daemon is enabled and
started by default; this can be controlled with `node['fb_kpatch']['enable']`.

### Packages
By default this cookbook keeps the kpatch-runtime package up-to-date, but if you
want to manage them locally, simply set
`node['fb_kpatch']['manage_packages']` to false.
