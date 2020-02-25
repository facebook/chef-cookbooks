fb_screen Cookbook
==================
This cookbook installs and manages the `screen` package.

Requirements
------------

Attributes
----------
* node['fb_screen']['manage_packages']

Usage
-----
Include `fb_screen` in your runlist to use it. You can opt out of package
management by settings `node['fb_screen']['manage_packages']` to `false`.
