fb_choco
==========
This cookbook installs and configures chocolatey for Windows.

Requirements
------------
`chef-client` version 15.11.8 or higher.

Attributes
----------
* node['fb_choco']['enabled']
* node['fb_choco']['bootstrap']
* node['fb_choco']['bootstrap']['version']
* node['fb_choco']['bootstrap']['choco_download_url']
* node['fb_choco']['config']
* node['fb_choco']['features']
* node['fb_choco']['source_blocklist']
* node['fb_choco']['sources']

Usage
-----
include_recipe 'fb_choco'

In order to have fb_choco manage bootstrapping, the
`node['fb_choco']['enabled']['bootstrap']` should be set to `true`.

Set the `node['fb_choco']['enabled']['manage']` attribute to `true` if you
would like to have fb_choco manage configuration of chocolatey
to manage sources, config settings, and features.

### Bootstrapping
fb_choco can bootstrap chocolatey onto machine using the `fb_choco_bootstrap`
resource.
You can specify your own internal download url for the chocolatey
installation, by default this url points to the latest version of
available from chocolatey.org.
You may also specify the desired version of chocolatey that you want
installed, and the resource will update the chocolatey installation
if the software version is lower than the version defined in the attribute.

To modify these settings simply do:

```
node.default['fb_choco']['bootstrap'] = {
  'version' => '0.10.15',
  'choco_download_url' => "#{internal_download_url}",
}
```

### Configuration
To modify a config setting simply do:
`node.default['fb_choco']['config'][$SETTING] = $VALUE`
If you would like to change any of these settings refer to the
online documentation for additional context on what these settings do
and what values are expected:
https://chocolatey.org/docs/chocolatey-configuration#config-settings

### Sources
To add a source to the chocolatey configuration, merge a hash into
`node['fb_choco']['sources']` with the feed name as the primary key, followed
by a hash that includes the source location.  For example:

```
node.default['fb_choco']['sources']['bacon'] = {
  'source' => 'http://bacon.es.yummy',
}
```

This will append `bacon` to the chocolatey config and so it can be used:

```
PS C:\> choco sources
bacon - http://bacon.es.yummy | Priority 0.
```

You can also maintain a blocklist of sources that can be removed as some
sources might be declared to be unsafe by systems administrators.

To blocklist a source, append a string with the source's URL to the list:

```
node.default['fb_choco']['source_blocklist'] << 'http://bacon.es.yummy'
```

When chef converges it will go through the blocklist and remove offending
entries before rendering the template to disk:

```
[2016-06-28T17:05:27-07:00] WARN: [your_recipe_name]: http://bacon.es.yummy
is blocklisted, removing.
```

### Features
To manage a feature in chocolatey, you can merge a hash into the
`node['fb_choco']['features']` attribute with the feature being the key,
and the value being set as either `true` or `false` depending on whether
you would like to enable or disable the feature.

For example, you can set multiple features by doing the following:

```
{
  'allowEmptyChecksumsSecure' => true,
  'allowGlobalConfirmation' => false,
}.each do |k, v|
  node.default['fb_choco']['features'][k] = v
end
```

Chocolatey, of course, must actually support the features you are managing.
For additional context on Chocolatey features see the online documentation:
https://docs.chocolatey.org/en-us/configuration#features
