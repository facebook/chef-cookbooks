fb_ldconfig Cookbook
====================
This cookbook manages `/etc/ld.so.conf` and the contents of `/etc/ld.so.conf.d`.

Requirements
------------
CentOS

Attributes
----------
* node['fb_ldconfig']['ld.so.conf']

Usage
-----
Include `fb_ldconfig` and append to `node['fb_ldconfig']['ld.so.conf']` any
additional paths the dynamic linker should use.

```
node.default['fb_ldconfig']['ld.so.conf'] << '/usr/local/lib'
```

This cookbook will delete any configs under `/etc/ld.so.conf.d` that aren't
owned by an installed RPM package.
