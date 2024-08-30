fb_sysstat Cookbook
===================
This cookbook installs and manages sysstat.

Requirements
------------

Attributes
----------
* node['fb_sysstat']['manage_packages']

Usage
-----
Include the cookbook in your recipe or runlist.

### Packages
By default this cookbook keeps the sysstat package up-to-date, but if you
want to manage them locally, simply set
`node['fb_sysstat']['manage_packages']` to false.
