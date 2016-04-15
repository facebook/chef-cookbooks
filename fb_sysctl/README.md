fb_sysctl Cookbook
====================
This cookbook provides sysctl functionality to Chef users.

Requirements
------------

Attributes
----------
* node['fb_sysctl'][$SYSCTL] = $VALUE

Usage
-----
Anywhere, in any cookbook, you can set a sysctl in a RECIPE as follows:

    node.default['fb_sysctl'][$SYSCTL] = $VALUE

For example:

    node.default['fb_sysctl']['vm.swappiness'] = 70
