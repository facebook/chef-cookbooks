fb_fluentbit Cookbook
========================
This cookbook installs the fluentbit daemon and optionally plugins for it.

Attributes
----------
* node['fb_fluentbit']['service_config']
* node['fb_fluentbit']['external_config_url']
* node['fb_fluentbit']['plugins']

Usage
-----
Include `fb_fluentbit::default` recipe to install fluentbit.

Cookbook provides 2 options to create fluentbit config:
 - Configuration template
 - Fetching existing config from url

Fluentbit allows you to have multiple instances of the same plugins,
for example multiple tail plugin instances to get logs from multiple files.
Fluentbit also supports built-in and external plugins.
These theses are reflected in the plugin API.
If you set `package_name` property of fb_fluentbit plugin map to plugin package name
this package will be installed. You also need to configure `external_path` property
for external plugins to specify path where plugin .so file can be found after
package installation.

### Customizing Plugins
There is plugin structure to add in node['fb_fluentbit']['plugins']:

```ruby
{
      'type' => 'INPUT|OUTPUT|FILTER - type of plugin, mandatory',
      'name' => 'name of plugin, mandatory',
      'package_name' => 'External plugin, shipped as rpm',
      'external_path' => 'External plugin, path to .so binary',
      'plugin_config' => {
          'config_param1' => 'custom plugin config vars'
      },
}
```

To start correctly, at least one INPUT and OUTPUT plugin must be configured.
Please note that no plugins are configured by default.
You are also responsible for giving a descriptive name for the key
in the plugin map. This name is not used in the configuration,
but it is needed to distinguish one plugin from another.
We recommend the format `<cookbook_name_goal`. For example:
`fbinstance_scribe`.
Important: by default, if you do not use fields `Tag` and `Match`,
all data from input plugins will be sent to all output ones.
Therefore, please use these fields whenever possible.
