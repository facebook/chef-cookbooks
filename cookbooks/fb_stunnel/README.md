fb_stunnel Cookbook
===================
Manage stunnel service and configuration

Requirements
------------

Attributes
----------
* node['fb_stunnel']['enable']
* node['fb_stunnel']['config']
* node['fb_stunnel']['config'][$CONFIG]
* node['fb_stunnel']['sysconfig'][$CONFIG]

Usage
-----
### Config

The config is mapped 1:1 to an INI file with the exception of the
`_create_self_signed_cert` key described below. The top-level key is the INI
section, and below that are expected to be simple key-value pairs. For example:

```ruby
node.default['fb_stunnel']['config']['my_www'] = {
  'accept' => 443,
  'connect' => '127.0.0.1:8080',
  'cert' => '/etc/stunnel/www.cert',
  'key' => '/etc/stunnel/www.key',
}
```

Would create:

```text
[my_www]
accept = 443
connect = 127.0.0.1:80
cert = /etc/stunnel/www.cert
key = /etc/stunnel/www.key
```

### Sysconfig

The sysconfig will generate `/etc/sysconfig/stunnel` on RH-like OSes or
`/etc/default/stunnel` on Debian-like systems. This must be simple key-value
pairs, and everything is 1:1 mapped to the final file **except** `enabled`
which is driven by the `node['fb_stunnel']['enable']` attribute.

Note that you should use low-casing for consistency, we upcase all keys.

For example you can do:

```ruby
node.default['fb_stunnel']['config']['rlimits'] = '-n 4096 -d unlimited'
```

Will render as:

```text
RLIMITS="-n 4096 -d unlimited"
```

Note that `files` defaults to `/etc/stunnel/fb_tunnel.conf`, the file this
cookbook writes out so that any other files in that directory do not affect the
service.

### Auto-creation of self-signed certificates

If a given section in `config` has the key `_create_self_signed_cert` **and**
has **both** a `cert` and `key` key, then we will create a self-signed
certificate for you. It will only do this if files do not already exist in that
place.
