fb_smokeping Cookbook
=====================
Configures and installs Smokeping, a network latency grapher

Requirements
------------
* For HTTPS/TLS support:`echoping` may need rebuilt with `--with-ssl`
* For IPv6 support: `fping` may need rebuilt with `--enable-ipv6`

Attributes
----------
* node['fb_smokeping']['general']
* node['fb_smokeping']['probes']['DNS']
* node['fb_smokeping']['probes']['FPing']
* node['fb_smokeping']['probes']['FPing6']
* node['fb_smokeping']['probes']['EchoPingHttp']
* node['fb_smokeping']['probes']['EchoPingHttps']
* node['fb_smokeping']['secrets']
* node['fb_smokeping']['targets']

Usage
-----

Include this cookbook from a recipe that runs on the server you want to
monitor from.

Smokeping supports measuring round trip times of ICMP pings, HTTP request
latency, and DNS lookup latency. It can be customized to do other types
of probes as well, but the cookbook may need to be modified.

The smokeping daemon is in charge of polling, saving data to RRD files. There
is a CGI script that provides the web UI at http://host/smokeping/smokeping.cgi

### Configuration
Define targets to probe via `node['fb_smokeping']['targets']`. This
attribute is a hash of hashes, in the same hierarchical fashion as the
Smokeping "Targets" file.  The top-level hash is global Targets
configuration in key=>value form, the second level hash being a group name
with any menu/title names in key=>value form, and the third level being
individual hosts to probe with their options also in key=>value form.

For example, this generates a Smokeping config with two top-level groups
named `Site_A` and `Site_B`, with three hosts to probe. Two will use standard
ICMP pings, and one will use a HTTP GET and measure the response time.

```bash
node.default['fb_smokeping']['targets']['Site_A'] = {
  'host1_example_com' => {
    'title' => 'My coffee maker',
    'host' => 'host1.example.com',
  },
  'host2_example_com' => {
    'title' => 'host2.example.com',
    'host' => 'host2.example.com',
  },
}

node.default['fb_smokeping']['targets']['Site_B'] = {
  'host3_example_com' => {
    'title' => 'host3.example.com (HTTPS ping to /webui/)'
    'host' => host3.example.com',
    'probe' => 'EchoPingHttps',
    'url' => '/artifactory/webapp/',
  },
}
```

Hash keys must not contain any periods, because Smokeping will use these
internally as filenames and it breaks things.  Underscores and dashes are
fine.

```bash
This is OK:

node.default['fb_smokeping']['targets']['Site_A'] = {
  'host1_example_com' => {...},
}

This is bad (periods in Site.A and the hostname):

node.default['fb_smokeping']['targets']['Site.A'] = {
  'host1.example.com' => {...},
}

```

### Probes
This cookbook configures five standard probes, IPv4 ICMP ping
(FPing), IPv6 ICMP ping (FPing6), HTTP GET (EchoPingHttp), HTTPS GET
(EchoPingHttps), and DNS lookup (DNS).

By default the probe is ICMP ping (FPing).  This can be overridden at a
group level or individual host level.

Probes can also be added/removed by setting the appropriate attribute values
under `node['fb_smokeping']['probes']`

### How to read graphs
There's a few dimensions of data packed into Smokeping charts which make
them useful but confusing to interpret at first.

Smokeping will send X probes in a row every Y seconds. The colored bar
represents any probe loss (green/purple/red). The position of the
colored bar on the y-axis is the RTT average of the probe. The "smoke" is
the standard deviation of all the probes.

*TL;DR:*

Green line, little or tight band of smoke: no packet/probe loss, no variation
in probe RTT latency. Life is good.

Purple line, wide band of "smoke": packet/probe loss, lots of variability in
probe RTT latency. Things are not going well.

Red line: severe, if not total, packet/probe loss.

*Time units on y-axis:*
* `u` - Microseconds
* `m` - Miliseconds
* `s` - Seconds
