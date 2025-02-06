fb_ethers Cookbook
====================
This cookbook configures `/etc/ethers` and provides an API for modifying all
aspects of the `/etc/ethers` file.

Requirements
------------

Attributes
----------
* node['fb_ethers']['entries']
* node['fb_ethers']['manage_packages']

Usage
-----
Add MAC address to hostname mappings using the `node['fb_ethers']['entries']`
attribute. Example:

```
node.default['fb_ethers']['entries'] = {
  'fc:15:b4:8f:3b:34' => 'foo01',
  '94:de:80:69:dc:01' => 'foo02',
  '50:e5:49:2f:75:c6' => 'foo03',
}
```

### Packages
By default this cookbook keeps the net-tools package up-to-date, but if you
want to manage them locally, simply set
`node['fb_ethers']['manage_packages']` to false.
