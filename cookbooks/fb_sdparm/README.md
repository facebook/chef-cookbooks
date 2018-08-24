fb_sdparm Cookbook
==================
Allows setting of whitelisted sdparm parameters.

Requirements
------------

Attributes
----------
* node['fb_sdparm']['enforce']
* node['fb_sdparm']['settings']

Usage
-----
`node['fb_sdparm']['enforce']` (Boolean)
This determines if Chef will actually try to set any settings specified
for the role. Defaults to false to be safe.

`node['fb_sdparm']['settings']` (Hash)
This is a hash that specifies sdparm settings to apply to disks. The settings
are bifurcated by whether disks are rotational. We explicitly do not support
assigning settings by drive letter because drive letters are not guaranteed to
consistently map to devices.

Only WCE and RCD are supported for now. If you'd like to set another param,
update the `param_whitelist` in the custom resource definition.

Settings are applied with the `--save` option to make them durable to power
loss.

This recipe will always attempt to update the `cache_type` entry in sysfs if it
detects that it has become out of sync with what is set on the drive.

If updating drive settings or `cache_type` fails, we fail the Chef run.

You are responsible for ensuring this runs only on supported hardware. For
example, disks behind an LSI RAID card will always fail attempts to set values.
This will result in failing the Chef run.

Example:

```
node.default['fb_sdparm']['enforce'] = true
{
  'rotational' => {
    'WCE' => 1,
    'RCD' => 0,
  },
  'non-rotational' => {
    'WCE' => 1,
    'RCD' => 0,
  },
}.each do |type, tconfig|
  tconfig.each do |key, val|
    node.default['fb_sdparm'][type][key] = val
  end
end
```
