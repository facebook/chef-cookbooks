fb_networkd Cookbook
====================
Configure and manage networking using systemd-networkd.

Requirements
------------

Attributes
----------
* node['fb_networkd']['primary_interface']
* node['fb_networkd']['allow_dynamic_addresses']
* node['fb_networkd']['enable_tun']
* node['fb_networkd']['networks'][$NETWORK]['priority']
* node['fb_networkd']['networks'][$NETWORK]['config']
* node['fb_networkd']['links'][$LINK]['priority']
* node['fb_networkd']['links'][$LINK]['config']
* node['fb_networkd']['devices'][$DEVICE]['priority']
* node['fb_networkd']['devices'][$DEVICE]['config']
* node['fb_networkd']['notify_resources']

Usage
-----
Include `fb_networkd` to configure systemd-networkd on your system. This cookbook
leverages `fb_systemd` to install and enable the `systemd-networkd` service.

### Configuration Overview

#### `node['fb_networkd']['primary_interface']`
Sets the primary interface to use on a host. By default, `fb_networkd` will
define a stub configuration for the primary interface, which is denoted by
`node['fb_networkd']['primary_interface']` and defaults to `eth0`. If this is
changed, you may want to also remove the default configuration:

```ruby
node.default['fb_networkd']['primary_interface'] = 'eth2'
node.default['fb_networkd']['networks'].delete('eth0')
```

#### `node['fb_networkd']['allow_dynamic_addresses']`
Controls whether to fail if a dynamic address is found on one of the
interfaces. Examples of dynamic addresses include SLAAC or DHCP(v6).

#### `node['fb_networkd']['enable_tun']`
This boolean enables you to create TUN/TAP interfaces. Must be set explicitly.

#### node['fb_networkd']['networks'][$NETWORK]['priority']
#### node['fb_networkd']['links'][$LINK]['priority']
#### node['fb_networkd']['devices'][$DEVICE]['priority']
The default priorities for a configuration are defined by the
`DEFAULT_NETWORK_PRIORITY`, `DEFAULT_DEVICE_PRIORITY`, and
`DEFAULT_LINK_PRIORITY` constants, except for the primary interface which
defaults to priorities defined by `DEFAULT_PRIMARY_INTERFACE_NETWORK_PRIORITY`,
`DEFAULT_PRIMARY_INTERFACE_DEVICE_PRIORITY`, and
`DEFAULT_PRIMARY_INTERFACE_LINK_PRIORITY`. These can be overridden with their
respective attributes.

#### node['fb_networkd']['networks'][$NETWORK]['config']
#### node['fb_networkd']['links'][$LINK]['config']
#### node['fb_networkd']['devices'][$DEVICE]['config']
The mapping of values to `systemd-networkd` properties. Each `config` is a Hash
where each systemd-networkd configuration section is a key, and the value is
another Hash of properties and values. See below for an example.

To avoid situations where one configuration will match on all interfaces, the
`[Match]` or `[NetDev]` section of each configuration will always be set to the
name of the interface. So even if it is set in the attributes, `fb_networkd`
will overwrite it when it creates the configuration.

For example, these are the kind of configurations that would be generated for
the different systemd-networkd configuration types, given an interface named
`eth2`:

```ruby
$ cat 50-fb_networkd-eth2.network
[Match]
Name = eth2

$ cat 50-fb_networkd-eth2.netdev
[NetDev]
Name = eth2

$ cat 50-fb_networkd-eth2.link
[Match]
OriginalName = eth2
```

### Configuration Example

The following is an example of how to add a networks configuration file to
eth0:

```ruby
node.default['fb_networkd']['networks']['eth0'] = {
  'priority' => 1,
  'config' => {
    'Network' => {
      'Address' => [
        '2001:db00::1/64',
        '192.168.1.1/24',
        '2401:db00::1/64',
      ],
    },
    'Address' => [
      {
        'Address' => '2001:db00::1/64',
        'PreferredLifetime' => 'infinity',
      },
      {
        'Address' => '2401:db00::1/64',
        'PreferredLifetime' => '0',
      },
    ],
  }
}
```

This will generate the following configuration file:

```ruby
$ cat 1-fb_networkd-eth0.network
[Match]
Name = eth0

[Network]
Address = 2001:db00::1/64
Address = 192.168.1.1/24
Address = 2401:db00::1/64

[Address]
Address = 2001:db00::1/64
PreferredLifetime = infinity

[Address]
Address = 2401:db00::1/64
PreferredLifetime = 0
```

Refer to the upstream documentation for more details on how to configure
[networks](https://www.freedesktop.org/software/systemd/man/systemd.network.html),
[links](https://www.freedesktop.org/software/systemd/man/systemd.link.html) and
[virtual network devices](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html).

### Notifications
If the networkd configuration is changed, `fb_networkd` will fire delayed
notifications for resources listed in `node['fb_networkd']['notify_resources']`.
This is a `Hash` in the `resource` => `action` format. For example, setting:

```ruby
node.default['fb_networkd']['notify_resources'] = {
   'service[some_service]' => :restart,
}
```

will result in:

```
notifies :restart, 'service[some_service]'
```

If you need to stop a service before a networkd change is made (and then start
it against afterwards) you can use `node['fb_networkd']['stop_before']`.
This is a list of resource names which will be issued a :stop before the
networkd change is made, than a :start at the end of the run.

```ruby
node.default['fb_networkd']['stop_before'] << 'service[cool_service]'
```

### When can Chef make network changes
Network changes can be disruptive and have potential for major impact. To
mitigate this, `node.interface_change_allowed?(interface)` from `fb_helpers`
is used to gate interface changes. When it returns true, the corresponding
configuration files are allowed to be updated and systemd-networkd or
systemd-udevd will update the network interface accordingly. If it returns
false no configuration file or network changes will occur.
