fb_jq Cookbook
==============
Installs jq, a lightweight and flexible command-line JSON processor
and keeps it up to date. Not supported on non-Linux systems, or for distros
where the jq package is unavailable.

Requirements
------------

Attributes
----------
* node['fb_jq']['manage_packages']

Usage
-----
Just include the recipe in your runlist. If you'd rather manage the package
installation yourself, set `node['fb_jq']['manage_packages']` to `false`.
