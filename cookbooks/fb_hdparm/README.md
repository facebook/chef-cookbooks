fb_hdparm Cookbook
==================
Allows setting of specific hdparm parameters that we support at FB.

Requirements
------------

Attributes
----------
* node['fb_hdparm']['enforce']
* node['fb_hdparm']['settings']

Usage
-----
This recipe is automatically included on all platforms except
macos. However, by default this cookbook is not enabled. (See below)

`node['fb_hdparm']['enforce']` (Boolean)
This determines if Chef will actually try to set any settings specified
for the role. Defaults to false to be safe.

`node['fb_hdparm']['settings']` (Hash)
This is a hash of key/value pairs. Each key is an option to the hdparm
command that you would like to set, and value is the value to set the
param to.

NOTE: hdparm in general is capable of dangerous and destructive
      operations. Thus, we only allow a specific subset of options.
      These are hard-coded in the default hdparm recipe.

Example:
```
node.default['fb_hdparm']['enforce'] = true
node.default['fb_hdparm']['settings']['-W'] = 1
```
