fb_dhcprelay Cookbook
=====================
Manage ISC DHCP Relay

Requirements
------------

Attributes
----------
* node['fb_dhcprelay']['manage_packages']
* node['fb_dhcprelay']['sysconfig']

Usage
-----

ISC DHCP Relay is a very simple package which forwards DHCP requests and
responses across a router. It does not have a configuration file and is
configured purely through command-line options.

### Configuration (sysconfig)

The sysconfig hash is how you can configure dhcprelay. There are two values
here: `servers`, and `options`. On Debian-derived OSes, there is also
`interfaces`. All 3 are arrays.

**NOTE**: You must use all-lowercase keys in the `sysconfig` hash, this
cookbook will upcase them for you. Using non-all-lowercase keys will cause the
run to fail.

You must point `servers` to the list of DHCP servers to forward requests to.
Then, on Debian systems you'll want to specify which interface or interfaces to
listen to in `interfaces`. Finally, you'll want to specify, at a minimum the
`-iu` and `-id` options to specify upstream and downstream interface(s). For
example, let's say you have a 3-legged router with `eth0` being WAN, `eth1`
being the internal network that has a DHCP server and `eth2` being the internal
network without a DHCP server. On Debian-derived OSes you would do:

```ruby
{
  'servers' => ['10.0.0.200'], # whatever your DHCP server is
  'interfaces' => ['eth2'],
  'options' => ['-iu eth1', '-id eth2'],
}.each do |key, val|
  node.default['fb_dhcprelay']['sysconfig'][key] = val
end
```

Or on Fedora-derived OSes:

```ruby
{
  'servers' => ['10.0.0.200'], # whatever your DHCP server is
  'options' => ['-iu eth1', '-id eth2', '-i eth2'],
}.each do |key, val|
  node.default['fb_dhcprelay']['sysconfig'][key] = val
end
```

*NOTE*: Fedora's package does not include a sysconfig file or a way to specify
options, so this cookbook adds a drop-in unit file to add such functionality
and a sysconfig file. You can see
[bz#2348883](https://bugzilla.redhat.com/show_bug.cgi?id=2348883) for details.

### Packages

By default this cookbook will install the appropriate package(s). To disable
this set `node['fb_dhcprelay']['manage_packages']` to `false`.

### A note on EOL

Technically, ISC has deprecated DHCP Relay. However, it is still currently the
primary DHCP Relay used in the world and the only one widely packaged. OpenBSD
has forked it, but that fork is not yet available for other OSes. You can see
[this page](https://www.isc.org/blogs/dhcp-client-relay-eom/) for details.
