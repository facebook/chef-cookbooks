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
### Daemon
To install collectd include `fb_collectd::default`. Global settings can be
customized using the `node['fb_collectd']['globals']` attribute and individual
plugins can be enabled and configured using `node['fb_collectd']['plugins']`.
Example:

```ruby
node.default['fb_collectd']['global']['FQDNLookup'] = true
node.default['fb_collectd']['plugins']['cpu'] = nil
node.default['fb_collectd']['plugins']['syslog'] = {
  'LogLevel' => 'info',
}
```

On Debian systems, environment settings can be configured in 
`node['fb_collectd']['sysconfig']`; note that this attribute is ignored on
CentOS.

### Frontend
The collectd-web fronted can be installed with the `fb_collectd::fronted`
recipe. Use the `node['fb_collectd']['collection']` to customize its settings.
Note that this recipe will not install or configure a web server, so unless you
set one up the collection CGIs will not actually be available.
