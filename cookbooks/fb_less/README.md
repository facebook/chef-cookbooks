fb_less Cookbook
====================
This cookbook manages `less` and deploys a custom `lesspipe.sh`.

Requirements
------------

Attributes
----------
* node['fb_less']['manage_packages']

Usage
-----
Include `fb_less` into the relevant cookbooks. If you do not want `less` to be
installed automatically, set `node['fb_less']['manage_packages']` to `false`.
