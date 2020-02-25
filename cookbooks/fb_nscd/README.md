fb_nscd Cookbook
================
This cookbook provides configuration of nscd. If this cookbook is in your
runlist, you can tweak all nscd settings from within your own cookbook.

Requirements
------------

Attributes
----------
* node['fb_nscd']['configs'][$KEY][$VALUE]
* node['fb_nscd'][$TABLE][$KEY][$VALUE]

Usage
-----
You can tweak settings for any given cache settings table (`passwd`, `group`,
`hosts`) through `node['fb_nscd'][$TABLE][$KEY][$VALUE]`. You can also define
global settings via ``node['fb_nscd']['configs'][$KEY][$VALUE]`. Please refer
to the
[upstream documentation](http://man7.org/linux/man-pages/man5/nscd.conf.5.html)
for the available settings.

So for example, to enable hosts cache, you can do:

```
node.default['fb_nscd']['hosts']['enable-cache'] = 'yes'
```

You can then change any setting for a cache such as:

```
node.default['fb_nscd']['hosts']['positive-time-to-live'] = 300
```

If a cache is not enabled, the relevant settings will not be added to the config
file.

The nscd service will be started automatically if any caches are enabled and
explicitly stopped if no caches are enabled.
