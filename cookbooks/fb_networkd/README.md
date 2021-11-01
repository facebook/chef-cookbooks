fb_networkd Cookbook
====================
Configure and manage networking using systemd-networkd.

Requirements
------------

Attributes
----------
* node['fb_networkd']['primary_interface']
* node['fb_networkd']['networks'][$NETWORK]['priority']
* node['fb_networkd']['networks'][$NETWORK]['config']
* node['fb_networkd']['links'][$LINK]['priority']
* node['fb_networkd']['links'][$LINK]['config']
* node['fb_networkd']['devices'][$DEVICE]['priority']
* node['fb_networkd']['devices'][$DEVICE]['config']

Usage
-----
Include `fb_networkd` to configure networkd on your system. This cookbook
leverages `fb_systemd` to install and enable the `systemd-networkd` service.

By default, `fb_networkd` will define a stub config for the primary interface,
which is denoted by `node['fb_networkd']['primary_interface']` and defaults to
`eth0`. If this is changed, you may want to also remove the default config:

```ruby
node.default['fb_networkd']['primary_interface'] = 'eth2'
node.default['fb_networkd']['networks'].delete('eth0')
```

The default priorities for a configuration are defined by the
`DEFAULT_NETWORK_PRIORITY`, `DEFAULT_DEVICE_PRIORITY`, and
`DEFAULT_LINK_PRIORITY` constants, except for the primary interface which
defaults to priorities defined by `DEFAULT_PRIMARY_INTERFACE_NETWORK_PRIORITY`,
`DEFAULT_PRIMARY_INTERFACE_DEVICE_PRIORITY`, and
`DEFAULT_PRIMARY_INTERFACE_LINK_PRIORITY`. These can be overridden with their
respective attributes (example below).

Add networks, links and virtual network devices configurations to the
respective attributes, e.g.:

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

To avoid situations where one configuration will match on all interfaces, the
`[Match]` or `[NetDev]` section of each configuration will always be set to the
name of the interface. For example, this is how an interface named `eth2`
configured for the different network types might look like:

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

According to the systemd.netdev man page, virtual network devices are created as
soon as systemd-networkd is started. And if an existing network device with a
specified name already exists, systemd-networkd will use it as-is rather than
create its own. Thus, we advise against creating networks and devices with the
same name.

Refer to the upstream documentation for more details on how to configure
[networks](https://www.freedesktop.org/software/systemd/man/systemd.network.html),
[links](https://www.freedesktop.org/software/systemd/man/systemd.link.html) and
[virtual network devices](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html).

### When can Chef make network changes
Network changes can be disruptive and have potential for major impact. To
mitigate this, `node.interface_change_allowed?(interface)` from `fb_helpers`
is used to gate interface changes. When it returns true, the corresponding
configuration files are allowed to be updated and systemd-networkd or
systemd-udevd will update the network interface accordingly. If it returns
false no configuration file or network changes will occur.
