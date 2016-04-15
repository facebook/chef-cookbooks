fb_motd Cookbook
====================
This cookbook generates the Message of the Day file (/etc/motd)

Requirements
------------

Attributes
----------
* node['fb_motd']['extra_lines']

Usage
-----
To add anything to the /etc/motd file, simply add lines to this array:

    node['fb_motd']['extra_lines']
