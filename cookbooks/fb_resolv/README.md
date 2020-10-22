fb_resolv Cookbook
====================
This cookbook configures resolv.conf and provides an API for modifying all
aspects of resolv.conf

Requirements
------------

Attributes
----------
* node['fb_resolv']['domain']
* node['fb_resolv']['nameservers']
* node['fb_resolv']['options']
* node['fb_resolv']['search']
* node['fb_resolv']['sortlist']

Usage
-----
Include the cookbook to manage /etc/resolv.conf.

### Customizing Local Domain
Set `node['fb_resolv']['domain']` if you want to manually set a local domain name.

### Setting nameservers
Set `node['fb_resolv']['nameservers']` to the list of nameservers you want to use.
If you do not set any nameservers, the resolv.conf default is to assume a local
DNS server.

### Setting resolver options
Set `node['fb_resolv']['options']` in key/value format for setting options. The
list of options available will depend on the version of glibc. A value of nil
will exclude the :value notation.

Example:

```
node.default['fb_resolv']['options']= {
  'timeout' => 4,
  'attempts' => 3,
  'inet6' => nil,
}
```

Result:

```
options timeout:4
options attempts:3
options inet6
```

### Setting search domains
Set `node['fb_resolv']['search']` to modify the search list for hostname lookups.
This setting should be a list of search domains you want to try.

Example:

```
node.default['fb_resolv']['search'] = [
  'mysite.com',
  'myothersite.com',
]
```

Result:

```
search mysite.com myothersite.com
```

### Setting sortlist
Set `node['fb_resolv']['sortlist']` to the list of IP-address-netmask pairs you
want to use. The netmask is optional and defaults to the natural netmask of the
net specified.
