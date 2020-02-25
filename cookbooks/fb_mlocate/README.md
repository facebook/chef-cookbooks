fb_mlocate Cookbook
====================

Requirements
------------

Attributes
----------
* node['fb_mlocate']['want_mlocate']
* node['fb_mlocate']['prunefs']
* node['fb_mlocate']['prunepaths']

Usage
-----
If you want mlocate installed (which includes our custom
updatedb.conf), then set `node['fb_mlocate']['want_mlocate']` to true.

WARNING: If `node['fb_mlocate']['want_mlocate']` is set to false
(the default) then any existing instance of mlocate (including the conf
file associated with the RPM) will be removed.

`node['fb_mlocate']['prunefs']` contains a list of filesystem
types to not index. It corresponds to the PRUNEFS setting from
updatedb.conf(5)

`node['fb_mlocate']['prunepaths']` is a list of paths to exclude
from the index.  It corresponds to PRUNEPATHS from updatedb.conf(5)
