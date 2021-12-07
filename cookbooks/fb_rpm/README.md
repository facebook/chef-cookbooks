fb_rpm Cookbook
====================
This cookbook installs and configures RPM.

Requirements
------------

Attributes
----------
* node['fb_rpm']['allow_db_conversion']
* node['fb_rpm']['db_backend']
* node['fb_rpm']['macros']
* node['fb_rpm']['manage_packages']
* node['fb_rpm']['rpmbuild']

Usage
-----
Include the cookbook to keep RPM up to date. If you want to manage the RPM
packages on your own, set `node['fb_rpm']['manage_packages']` to `false`.

### Database backend
By default, `fb_rpm` will setup rpm to use the distribution default database
backend. This can be overridden by setting `node['fb_rpm']['db_backend']`.
Existing databased will not be converted, unless
`node['fb_rpm']['allow_db_conversion']` is also set to `true`.

### rpm-build and rpm-sign
Set `node['fb_rpm']['rpmbuild']` to `true` to also install RPM build tools
(including the the `rpmbuild` and `rpmsign` commands).

### Macros
You can set custom macros with the `node['fb_rpm']['macros']` attribute, e.g.:

```
node.default['fb_rpm']['macros']['%foo'] = 'bar'
```

The value can be numbers or strings with spaces, the value will not be quoted in
the resulting file as that's not necessary in RPM macro files.

Technically the keys can also have spaces, so if you wanted to make a key of
`%define foo` and a value of `bar`, that would work, though the `%define` syntax
isn't used for runtime macros.
