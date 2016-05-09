fb_securetty Cookbook
====================

Requirements
------------

Attributes
----------
* node['fb_securetty']['ttys']

Usage
-----
Add any additional securetty entries to the array 'ttys':

    # Allow root login on another console
    node.default['fb_securetty']['ttys'] << 'ttyS0'
