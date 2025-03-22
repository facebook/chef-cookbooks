fb_collectd Cookbook
====================
The `fb_collectd` cookbook installs and configures collectd, a statistics
collection and monitoring daemon.

Requirements
------------

Attributes
----------
* node['fb_collectd']['collection']
* node['fb_collectd']['globals']
* node['fb_collectd']['plugins']
* node['fb_collectd']['sysconfig']

Usage
-----
### Daemon configuration

To install collectd include `fb_collectd::default`. Global settings can be
customized using the `node['fb_collectd']['globals']` attribute and individual
plugins can be enabled and configured using `node['fb_collectd']['plugins']`.
Example:

```ruby
node.default['fb_collectd']['globals']['FQDNLookup'] = true
node.default['fb_collectd']['plugins']['cpu'] = nil
node.default['fb_collectd']['plugins']['syslog'] = {
  'LogLevel' => 'info',
}
```

This will render like:

```text
FQDNLookup true
LoadPlugin cpu
LoadPlugin syslog
<Plugin syslog>
  LogLevel info
</Plugin>
```

All plugins will also be loaded with a simple `LoadPlugin $PLUGIN` - if you
need the loading to have a configuration as well, use the `_load_config` key:

```ruby
node.default['fb_collectd']['plugins']['python'] => {
  '_load_config' => {
    'Globals' => true,
  },
  ...
}
```

which will render like so:

```text
<LoadPlugin python>
  Globals true
</LoadPlugin>
<Plugin python>
  ...
</Plugin>
```

Note that since collectd expects _most_ of its string config values to be unquoted,
we do not quote string values by default (otherwise things like `LogLevel` above
would error). If a value needs to be quoted, you can quote it in it's config:

```ruby
node.default['fb_collectd']['plugins']['apache'] => {
  'Instance "localhost"' => {
    'URL' => '"http://localhost/server-status?auto"',
  },
}
```

### Sysconfig

On Debian systems, environment settings can be configured in
`node['fb_collectd']['sysconfig']`; note that this attribute is ignored on
CentOS.

### Frontend

The collectd-web fronted can be installed with the `fb_collectd::frontend`
recipe. Use the `node['fb_collectd']['collection']` to customize its settings.
Note that this recipe will not install or configure a web server, so unless you
set one up the collection CGIs will not actually be available.
