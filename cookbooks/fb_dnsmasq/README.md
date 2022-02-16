fb_dnsmasq Cookbook
====================
This cookbook installs and configures dnsmasq, a small caching DNS proxy and
DHCP/TFTP server.

Requirements
------------

Attributes
----------
* node['fb_dnsmasq']['config']
* node['fb_dnsmasq']['enable']
* node['fb_dnsmasq']['systemd_overrides']

Usage
-----
Include `fb_dnsmasq` in your runlist to install dnsmasq. By default we enable
the daemon, set `node['fb_dnsmasq']['enable']` to `false` to disable it.
Configuration can be customized using `node['fb_dnsmasq']['config']` according
to the [upstream
documentation](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html).
Example:

```ruby
node.default['fb_dnsmasq']['config'] = {
  'dhcp-authoritative' => nil,
  'dhcp-range' => [
    '192.168.1.100,192.168.1.200,12h',
    '::1,constructor:eth0,ra-stateless,ra-names',
   ],
  'enable-ra' => nil,
  'server' => [
    '8.8.8.8',
    '8.8.4.4',
   ],
  'no-resolv' => nil,
  'read-ethers' => nil,
}
```

Unless the `no-hosts` config option is set, dnsmasq will read hostname to IP
mappings from `/etc/hosts`. This can be customized using the API provided by
the `fb_hosts` cookbook.

If the `read-ethers` config option is set, dnsmasq will read mac address to
hostname mappings from `/etc/ethers`. This can be customized using the API
provided by the `fb_ethers` cookbook.

### systemd_overrides
You can set any systemd_overrides in `node['fb_dnsmasq']['systemd_overrides']`,
and they will use the `fb_systemd_override` resource to create a drop-in file
for systemd. The default in this cookbook turns Restart=always on for the
service since some packages don't set it at all. Here's how you would set that
same thing explicitly:

```ruby
node.default['fb_dnsmasq']['systemd_overrides']['Service']['Restart'] = 'always'
```
