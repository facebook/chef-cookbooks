fb_network_scripts Cookbook
======================
Configure and manage networking devices

Requirements
------------

Attributes
----------
* node['fb_network_scripts']['allow_dynamic_addresses']
* node['fb_network_scripts']['enable_bridge_filter']
* node['fb_network_scripts']['enable_tun']
* node['fb_network_scripts']['interfaces'][$INTERFACE][$CONFIG]
* node['fb_network_scripts']['ifup']['ethtool']
* node['fb_network_scripts']['ifup']['extra_commands']
* node['fb_network_scripts']['ifup']['sysctl']
* node['fb_network_scripts']['interface_change_allowed_method']
* node['fb_network_scripts']['interface_start_allowed_method']
* node['fb_network_scripts']['linkdelay']
* node['fb_network_scripts']['manage_packages']
* node['fb_network_scripts']['network_changes_allowed_method']
* node['fb_network_scripts']['primary_interface']
* node['fb_network_scripts']['ring_params'][$INTERFACE]['max_rx']
* node['fb_network_scripts']['ring_params'][$INTERFACE]['max_tx']
* node['fb_network_scripts']['routing']['default_metric']
* node['fb_network_scripts']['routing']['extra_routes']

Usage
-----

### Node Methods
This cookbook provides the following node methods:

#### `node.eth_is_affinitized?`
Returns true if the eth MSI vectors are affinitized (i.e. they are spread
across all available CPUs).

#### `node.ip?(string)`
Returns true if the IP is configured in the host.

### General Configs

#### `node['fb_network_scripts']['allow_dynamic_addresses']`
Controls whether to fail if a dynamic address is found on one of the
interfaces. Examples of dynamic addresses include SLAAC or DHCP(v6).

#### `node['fb_network_scripts']['enable_tun']`
This boolean enables you to create TUN/TAP interfaces. Must be set explicitly.

#### `node['fb_network_scripts']['linkdelay']`
This is an integer that represents the number of seconds to wait bringing the
interface up during a network restart.

### `node['fb_network_scripts']['manage_packages']`
Controls whether to manage packages for `network-scripts`; defaults to `true`.

### Interface Configs
This cookbook also provides interface configuration:

To add an interface, you simply add a hash to the config:

```ruby
node.default['fb_network_scripts']['interfaces']['eth1'] = {
  #required configs
  'ip' => '10.0.0.12',
  'netmask' => '255.255.255.0',
  # optional configs
  'onboot' => 'yes',
  'bootproto' => 'static',
  'mtu' => 1500,
}
```

Note that `onboot` and `bootproto` are optional - they default to `yes` and
`static`, respectively.

There are other options:

* `ipv6` - v6 address
* `v6router` is evaluated if `want_ipv6` is `yes`, it is optional
and defaults to 'no'. If it is set to yes, this will enable IPv6 forwarding
for that particular interface.
* `v6secondaries` is additional v6 addresses to add to the interface
* `hotplug`
* `peer_outer_ip`, `peer_inner_ip`, `my_inner_ip` - for IPIP tunnels
* `bridge`, `ovs_bridge` - see Bridge Configuration below
* `gateway`
* `mtu` - MTU for this interface
* `extra_route_opts` - Route options for the default route (set by `gateway`).
* `hwaddr` - MAC address. Used to populate `HWADDR` key in `ifcfg-ethX` file.
  This is only present to help the system assert expressed configuration
  matches the system state. It cannot be used to rename interfaces. Format is
  common "01:23:45:67:89:ab". Case is ignored.

This will generate the `ifcfg-eth1` file.

If your primary interface is not `eth0`, but you want this behavior, you can
tell `fb_network_scripts`:

```ruby
node.default['fb_network_scripts']['primary_interface'] = 'eth2'
```

And this will "do the right thing". By default, the primary interface will be
setup to accept IPv6 Router Advertisements (but not autoconfiguration). This
can be changed by setting the relevant sysctl through the `fb_sysctl`
interface.

For the primary interface, you don't need to specify the IP or netmask, they'll
be pulled from fbwhoami. This is the default entry for eth0:

```ruby
node.default['fb_network_scripts']['interfaces']['eth0'] = {
  'bootproto' => 'static',
  'onboot' => 'yes',
}
```

Additional interfaces ("eth1" to "eth14") configured with IPv6 addresses in SeRF
will be automatically configured from fbwhoami unless manually configured by
adding `node.default['fb_network_scripts']['interfaces'][interface]`. This is
incompatible with bridging or when `primary_interface != eth0` and will fail with
an error. Talk to the OS Team if you have a use case that requires this.

#### MTU
MTU can be configured with the 'mtu' key, and MTU is a bit special in that you
can set the MTU on the default interface, and if nothing else is set on it, then
it will still automagically get configured based on fbwhoami data, but the MTU
setting will still be applied.

#### IPv6 Secondaries
`fb_network_scripts` will dynamically add/remove IPv6 addresses on interfaces to
match `v6secondaries` **without** restarting the interface. This is the only
interface configuration handled this way.

#### Bridge Configuration
If you want to set up an interface as part of a bridge, you can do:

```ruby
node.default['fb_network_scripts']['interfaces']['eth1'] = {
  'onboot' => 'yes',
  'bridge' => 'br0',
}
```

This will bind eth1 to the br0 bridge; you shouldn't specify any other options,
as bridged interfaces operate at L2 only. By default:
* netfilter on bridge member interfaces is disabled to prevent weirdness (see
  https://bugzilla.redhat.com/512206).
* the IPv6 stack on bridge member interfaces is disabled to prevent stray
  routes due to autoconfiguration
Again, settings can be overridden using the relevant sysctl. Note that in 3.18+
the `br_netfilter` module needs to be explicitly loaded to be able to toggle
the bridge netfilter sysctl. To enable bridge netfilter you can set:

```ruby
node.default['fb_network_scripts']['enable_bridge_filter'] = true
```

which will take care of setting the proper sysctls and loading the necessary
kernel modules.

You can setup the bridge itself as a normal interface:

```ruby
node.default['fb_network_scripts']['interfaces']['br0'] = {
  'ip' => '10.0.0.12',
  'netmask' => '255.255.255.0',
  'onboot' => 'yes',
  'bootproto' => 'static',
  'v6router' => 'no',
}
```

This will use a static configuration. You can also use the bridge as primary
interface with:

```ruby
node.default['fb_network_scripts']['primary_interface'] = 'br0'
```

### DSR Interfaces
If you rely on Direct Server Return (DSR) in your infrastructure, you probably
want to write a domain-specific wrapper. Nonetheless, it is possible to setup
DSR manually using `fb_network_scripts`.

To add a dummy interface for DSR you would do:

```ruby
node.default['fb_network_scripts']['interfaces']['dummy0'] = {
  'ip' => '1.1.1.2',
  'netmask' => '255.255.255.255',
}
```

We even have range support. When using range support, you should not specify
an IP on the main interface, it'll get `127.0.0.2`.

```ruby
node.default['fb_network_scripts']['interfaces']['dummy0'] = {
  'range' => {
    'start' => '1.1.2.37',
    'end' => '1.1.2.99',
    'clonenum' => 10,        # This is optional, default is 4
  }
}
```

The `clonenum` means that'll start at `dummy0:4`.

And of course, IPv6 is supported:

```ruby
node.default['fb_network_scripts']['interfaces']['ip6tnl0'] = {
  'ipv6' => '2401:db00:0:0:face:0:3:0',
}
```

While network-scripts do not support range files for IPv6, this cookbook will accept
v6 ranges and do the right thing:

```ruby
node.default['fb_network_scripts']['interfaces']['ip6tnl0'] = {
  'v6range' => {
    'start' => '2401:db00:0:0:face:0:3:10',
    'end' => '2401:db00:0:0:face:0:3:1f', # RANGES ARE ONLY PROPERLY HANDLED
  }                                       # FOR THE LAST OCTET
}
```

This will properly populate the `v6secondaries` key in the hash for you which
populates the `IPV6ADDR_SECONDARIES` entry in the ifcfg file.

### TUN/TAP Interfaces
Creating a TAP interface is easy. Enable TUN networking:

```ruby
node.default['fb_network_scripts']['enable_tun'] = true
```

and configure your interface (with a `tap` prefix):

```ruby
node.default['fb_network_scripts']['interfaces']['tap0'] = {
  'ip' => '192.168.100.1',
  'netmask' => '255.255.255.0',
}
```

### VLAN Interfaces
You can setup the VLAN interface (interface format `<interface>.<vlan_id>`):

```
node.default['fb_network_scripts']['interfaces']['eth0.4088'] = {
  'ip' => '10.0.0.12',
  'netmask' => '255.255.255.0',
  'onboot' => 'yes',
  'bootproto' => 'static',
  'v6router' => 'no',
  'vlan' => 'yes',
  'hotplug' => 'no',          # This is optional, default is yes
}
```

This will create a VLAN on eth0 interface.

If hotplug option is set to no, one can be used to prevent a channel
bonding interface from being activated when a bonding kernel module
is loaded.

### ifup
This cookbook will install a custom ifup script, which is run every time an
interface is bounced.

#### `node['fb_network_scripts']['ifup']['ethtool']`
This is an array of hashes that allow you to specify ethtool commands to run at
interface start time. It's hooked into the `ifup-local` this cookbook manages.

The hashes have 6 entries:

* **interface** - the interface this applies to (e.g. `eth0`)
* **subcommand** - the `ethtool` subcommand (e.g. `-L` to set channels)
* **field** - The field to set (e.g. `combined`)
* **value** - The value to set (e.g. `16`)
* **check_field** - The name of the field to check in the output if it's
  different from `field` (e.g. `Combined`)
* **check_pipe** - A command to pipe the output of the ethtool check command
  to format it for checking.

For example to set 16 queues on Intel NICs:

```ruby
node.default['fb_network_scripts']['ifup']['ethtool'] << {
  'interface' => 'eth0',
  'subcommand' => '-L',
  'field' => 'combined',
  'value' => '16',
  'check_field' => 'Combined',
  'check_pipe' => 'egrep -i -A5 current',
}
```

Would, on interface startup run:

```
ethtool -L eth0 | egrep -i -A5 current | awk '/Combined:/{print $2}'
```

And compare that to `16`. If it was not `16` then it would run:

```
ethtool -L eth0 combined 16
```

#### `node['fb_network_scripts']['ifup']['extra_commands']`
This is an array of commands that will be executed at the end of the ifup
script. It can be used to implement any custom logic that should be run at
interface bounce time.

#### `node['fb_network_scripts']['ifup']['sysctl']`
This is a hash of key-value sysctl settings that will be applied on every
interface (re)start, assuming they're not already being set by `fb_sysctl`.

### Routing Configs
Routing is configured through the `routing` hash. Each entry conforms
to a configuration variable ifup-local cares about and gets added to
`/usr/local/etc/ifup-local.d/config`.

* **NOTE 1**: `..._offsets` entries are arrays and must be so.
* **NOTE 2**: No options are required except `ECMP_NEXTHOPS_OFFSETS` and
`DEFAULT_NEXTHOPS_OFFSETS` which have defaults already.

#### `node['fb_network_scripts']['routing']['default_metric']`

Metric to use for the default route in the default table.

#### `node['fb_network_scripts']['routing']['extra_routes']`

Helps you add extra routes to primary interface.
For non primary interface, say ethX, you can use below:

#### `node['fb_network_scripts']['routing']['extra_routes_ethX']`

In both cases, this is a hash of the form:

```ruby
$some_net => {
 'src' => $some_source_ip, # optional
 'gw' => $some_gw, # optional
 'dev' => $ethX
}
```

For example:

```ruby
node.default['fb_network_scripts']['routing']['extra_routes_eth3']['::0/0'] = {
  'gw' => 'fe80::face:b00c',
  'from' => '2401:db00:1050:a16f:face:0:f:0',
  'dev' => 'eth13',
}
```

To add multiple entries for the same key, one can create an array of hashes:

```ruby
node.default['fb_network_scripts']['routing']['extra_routes_eth13']['::0/0'] = [{
  'gw' => 'fe80::face:b00c',
  'from' => '2401:db00:1050:a16f:face:0:f:0',
  'dev' => 'eth13',
  'mtu' => '1500',
}, {
  'gw' => 'fe80::face:b00c',
  'from' => '::',
  'dev' => 'eth13',
  'mtu' => '9000',
}]

```

If `gw` is left out, then it is assumed you want to use the default gateway,
in which case you may also specify a `src`.

### When can Chef make network changes
Network changes can be disruptive and have potential for major impact. To
mitigate this, `fb_network_scripts` is limited to making host network changes
when a host is in provisioning (`node.firstboot_any_phase?`) or when it has been
explicitly granted permission to make changes to the network based on the
presence of a flag file.  This flag file can be automatically placed onto hosts
using automation, for example:

* Chef decides a network change is needed
* if the host is not in provisioning, and the flag file is not present, Chef
  requests permission by triggering an alarm
* automation consumes the alarm and fires a rate-limited remediation which will
  ungate Chef
* a subsequent Chef run will still need to make the network change, but it will
  now be allowed to change the network, and will proceed in normal fashion

#### Exceptions
Chef is allowed to make non-disruptive networking changes without explicit
permission for the following cases:
* addition / removal of IPv6 secondary addresses
* MTU changes
* setup / management of tunnel interfaces: `ip6tnl0`, `tunlany0`, `tunl0`

#### Using custom logic
If you'd like to override the default logic for allowing network changes, you
can set the `node['fb_network_scripts']['network_changes_allowed_method']`
attribute to a method to be called, e.g.

```ruby
node.default['fb_network_scripts']['network_changes_allowed_method'] =
  FB::NetworkScriptsSettings.method('network_changes_allowed?')
```

will use the `FB::NetworkScriptsSettings.network_changes_allowed?` method, which
should accept a single `node` argument and return a boolean. The attributes
`node['fb_network_scripts']['interface_start_allowed_method']` and
`node['fb_network_scripts']['interface_change_allowed_method']` work in the same
way, taking a `node` and an `interface` in and returning a boolean.
