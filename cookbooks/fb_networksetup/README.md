fb_networksetup Cookbook
======================
Configure and manage networking on macOS using networksetup.

Requirements
------------

Attributes
----------
* node['fb_networksetup']['services'][$SERVICE][$CONFIG]

Usage
-----
This cookbook is centered around _services_, which on macOS map network
configuration to _hardware ports_ (i.e. interfaces). An interface can have
multiple services, but a given service can only be bound to one interface.

To configure a service, add a hash to the config:

```ruby
node.default['fb_networksetup']['services']['Ethernet'] = {
  'interface' => 'en0',
  'ipv4' => {
    'address' => '10.0.0.12',
    'netmask' => '255.255.255.0',
    'gateway' => '10.0.0.1',
  },
  'ipv6' => {
    'address' => 'face:b00c::12',
    'netmask' => '64',
    'gateway' => face:b00c::1',
  },
}
```

By default, if an address type is not specified it will not be managed.
The default behavior for a managed address type is to disable it if no
address information is specified. For example, specifying

```ruby
node.default['fb_networksetup']['services']['Ethernet'] = {
  'interface' => 'en0',
  'ipv6' => {
    'address' => 'face:b00c::12',
    'netmask' => '64',
    'gateway' => face:b00c::1',
  },
}
```

will not apply any `ipv4` settings. However,

```ruby
node.default['fb_networksetup']['services']['Ethernet'] = {
  'interface' => 'en0',
  'ipv4' => {
    'manage' => true,
  }
  'ipv6' => {
    'address' => 'face:b00c::12',
    'netmask' => '64',
    'gateway' => face:b00c::1',
  },
}
```

will disable ipv4 as no address is specified.
