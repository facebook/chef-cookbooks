fb_hostname Cookbook
===============================
Manage the system hostname.

Requirements
------------

Attributes
----------
* node['fb_hostname']['hostname']
* node['fb_hostname']['pretty_hostname']

Usage
-----
Just include the cookbook and set the attributes for the hostname flavors you'd
like to manage. By default these are all `nil`, which will leave them
unmanaged.
