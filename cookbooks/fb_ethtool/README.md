fb_ethtool Cookbook
===================
This cookbook installs and manages the ethtool package.

Requirements
------------

Attributes
----------
* node['fb_ethtool']['manage_packages']

Usage
-----
Include `fb_ethtool` in your runlist to use it. You can opt out of package
management by setting `node['fb_ethtool']['manage_packages']` to `false`.
