fb_ipset Cookbook
====================
Basic cookbook to manage ipsets.

Requirements
------------
RHEL like system, with ipset support in kernel/modules

Attributes
----------
* node['fb_ipset']['enable']
* node['fb_ipset']['manage_packages']
* node['fb_ipset']['auto_cleanup']
* node['fb_ipset']['sets'][$SET_NAME]['members']
* node['fb_ipset']['sets'][$SET_NAME]['type']
* node['fb_ipset']['sets'][$SET_NAME]['family']
* node['fb_ipset']['sets'][$SET_NAME]['hashsize']
* node['fb_ipset']['sets'][$SET_NAME]['maxelem']

Usage
-----
Include `fb_ipset` to manage ipset on a machine. This cookbook manages the ipset
package by default; set `node['fb_ipset']['manage_packages']` to `false` if
you'd rather do that yourself.

### Sets
The "name" of a set is arbitrary, it's simply there so it can be
modified/reference later from iptables.

All attributes except for `members` are passed through to the ipset create
command. For example, if you have the following:

```ruby
include_recipe 'fb_ipset'

node.default['fb_ipset']['enable'] = true
node.default['fb_ipset']['sets']['rfc1918'] = {
  'type' => 'hash:net',
  'family' => 'inet',
  'hashsize' => '64',
  'maxelem' => '4',
  'members' => ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']
}
```

The command that will be used to create the ipset is:
`ipset create rfc1918 hash:net family inet hashsize 64 maxelem 4`

The commands that will be used to add the members to the ipset are:
```
ipset add rfc1918 10.0.0.0/8
ipset add rfc1918 172.16.0.0/12
ipset add rfc1918 192.168.0.0/16
```

See `ipset help` for more information of possible set types and their parameters

### Reload triggers
You can subscribe to `fb_ipset[fb_ipset]` if you need to trigger on ipsets
reloading.
