fb_chrony Cookbook
==================
This cookbook configures Chrony on a system.

Requirements
------------

Attributes
----------
* node['fb_chrony']['config']
* node['fb_chrony']['servers']
* node['fb_chrony']['pools']
* node['fb_chrony']['default_options']
* node['fb_chrony']['leap']

Usage
-----
Include `fb_chrony::default` to manage Chrony. Servers and pools can be
configured via the `node['fb_chrony']['servers']` and
`node['fb_chrony']['pools']` attributes. These can be either lists or hashes;
in the first case, each item will have the same options, as defined in
`node['fb_chrony']['default_options']`. In the latter, items with empty values
will use `node['fb_chrony']['default_options']`, while the other will use the
value specified. For example:

```ruby
node['fb_chrony']['default_options'] = %w{iburst}
node.default['fb_chrony']['servers'] = {
  'ntp1.example' => %w{iburst xleave},
  'ntp2.example' => [],
}
node.default['fb_chrony']['pools'] = %w{
  ntp1pool.example
  ntp2pool.example
end
```

will result in the following configuration:

```
server ntp1.example iburst xleave
server ntp2.example iburst

pool ntp1pool.example iburst
pool ntp2pool.example iburst
```

Other settings can be defined in `node['fb_chrony']['config']`.
