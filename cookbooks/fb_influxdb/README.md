fb_influxdb Cookbook
====================
Installs and configures influxdb

Requirements
------------
This cookbook only works in Debian and Ubuntu since influxdb is not packaged
in Fedora or EPEL.

Attributes
----------
* node['fb_influxdb']['manage_packages']
* node['fb_influxdb']['config']

Usage
-----
NOTE: This cookbook currently assumes Influx 1.x.

### Packages

This cookbook will install both the server and client packages for you. If you
want to manage packages yourself, set `node['fb_influxdb']['manage_packages']`
to `false`.

### Configuration

A basic configuration is present in `node['fb_influxdb']['config']` which will
allow a local influxdb instance to startup. It directly maps to the config
format. All top-level sections are already created, add to them from your own
cookbook like:

```ruby
node.default['fb_influxdb']['config']['logging']['level'] = 'debug'
```
