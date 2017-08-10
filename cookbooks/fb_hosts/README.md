fb_hosts Cookbook
====================
This cookbook configures /etc/hosts and provides an API for modifying all
aspects of the /etc/hosts file

Requirements
------------

Attributes
----------
* node['fb_hosts']['primary_ipaddress']
* node['fb_hosts']['primary_ip6address']
* node['fb_hosts']['host_aliases']
* node['fb_hosts']['extra_entries']
* node['fb_hosts']['enable_hostname_entries']

Usage
-----
## Host aliases
fb_hosts will always include the value of `node['fqdn']` as a hostname, and you
can add additional aliases via `host_aliases`:

    node.default['fb_hosts']['host_aliases'] << 'new_host_alias_entry'

We use `primary_address` and `primary_ip6address` as the addresses to set as
yourself. If you do not set these, it will use `node['ipaddress']` and
`node['ip6address']` respectively.

## Other host entries
You can add new entries into the hosts like this:

    node.default['fb_hosts']['extra_entries']['10.1.1.1'] = [
      'somehostname.mydomain.com',
    ]

## Hostname entries
By default, `fb_hosts` will make entries in /etc/hosts pointing your real
hostname to your primary IPv4/IPv6 addresses. You almost certainly want that.
However, some enterprise applications can't handle these, so you can disable
them by setting `enable_hostname_entries` to false:

    node.default['fb_hosts']['enable_hostname_entries'] = false
