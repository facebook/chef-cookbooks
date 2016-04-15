fb_swap Cookbook
====================
This cookbook enables or disables swap partitions.

Requirements
------------

Attributes
----------
* node['fb_swap']['enabled']

Usage
-----
You can disable swap with:

    node.default['fb_swap']['enabled'] = false

or you can enable swap if its off like this:

    node.default['fb_swap']['enabled'] = true

The default is `true`.
