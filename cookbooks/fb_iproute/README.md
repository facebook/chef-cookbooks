fb_iproute Cookbook
=================
This cookbook manages iproute.

Requirements
------------
CentOS

Attributes
----------
* node['fb_iproute']['manage_packages']

Usage
-----
Just include the cookbook in your runlist. If you'd like to manage the iproute
packages yourself, set `node['fb_iproute']['manage_packages']` to false.
