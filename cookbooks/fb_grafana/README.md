fb_grafana Cookbook
===================
This cookbook installs, configures, and manages Grafana

Requirements
------------

Attributes
----------
* node['fb_grafana']['config']
* node['fb_grafana']['config'][$SECTION]
* node['fb_grafana']['config'][$SECTION][$CONFIG]
* node['fb_grafana']['gen_selfsigned_cert']
* node['fb_grafana']['plugins']
* node['fb_grafana']['plugins'][$PLUGIN]
* node['fb_grafana']['datasources']
* node['fb_grafana']['datasources'][$NAME]
* node['fb_grafana']['datasources'][$NAME][$CONFIG]
* node['fb_grafana']['version']

Usage
-----
### Service configuration
The `config` object maps directly to the `grafana.ini` config file. The
top-level keys are sections in the INI file and below that are the key-value you
pairs of that section. For example:

```ruby
node.default['fb_grafana']['config']['server']['protocol'] = 'https'
```

Will render as:

```ruby
[server]
protocol = https
```

It's worth noting Grafana does not provide any sort of validator for their
config file, so you should test your configuration carefully. Further, Grafana
reports success to systemd and then later crashes on a bad config.

### Version
As of this writing, this cookbook will add the upstream grafana debian repos to
the local config, install the grafana PGP key, and install the version specified
in `version` using apt. If `version` is `nil`, the latest will be installed.

### Certificates
If `gen_selfsigned_cert` is `true`, then this cookbook will generate a
self-signed certificate, if no certificate is present.

### Plugins
The `plugins` hash is a `name` => `version` hash. If the `version` is nil, then
the latest version will always be installed. If the `version` is set, then that
version will be pinned.

Note that we ensure these are managed idempotently, a plugin is never touched if
it's on the desired version.

### Data Sources
You can populate datasources by adding them to the hash
`node['fb_grafana']['datasources']`. Note that this uses the Provisioning
method of Grafana, meaning new entries that show up in this directory will
be setup, but further maintenance of them is done through the UI/API (the
source of truth is in Grafana's DB).

These take the data as described in [the
docs](https://grafana.com/docs/administration/provisioning/) for provisioning
yaml files, with one exception. The key is used to populate the `name`
attribute, you need not populate it. In otherwords:

```ruby
node.default[''fb_grafana']['datasources']['prometheus'] = {
  'type' => 'prometheus',
  'orgId' => 1,
  'url' => "http://localhost:9090",
  'access' => 'proxy',
  'isDefault' => true,
  'editable' => false,
}
```

will be rendered as:

```yaml
datasources:
- type: prometheus
  orgId: 1
  url: http://localhost:9090
  access: proxy
  isDefault: true
  editable: false
  name: prometheus
```

This is done so that it is easy to modify a config later in the run.
