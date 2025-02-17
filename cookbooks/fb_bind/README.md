fb_bind Cookbook
================

Requirements
------------

Attributes
----------
* node['fb_bind']['config']
* node['fb_bind']['default_zone_ttl']
* node['fb_bind']['empty_rfc1918_zones']
* node['fb_bind']['include_record_comments_in_zonefiles']
* node['fb_bind']['manage_packages']
* node['fb_bind']['sysconfig']
* node['fb_bind']['zones']

Usage
-----

This cookbook manages all aspect of your Bind9 service from config to zones.
It has a variety of features and helpers to make manging your config as easy
as possible. It has taken a variety of features that both the Debian and Fedora
echosystems provide for best practices, but also uses the directories and setups
of your distro appropriately.

Like all FB-API cookbooks it enforces a specific place for the configuration
files, but allows you to change the contents of those files in any way.

This means that on Redhat-like OSes, the configuration file is not in the
default place (it's in `/etc/bind/named.conf` if you use this cookbook).

Importantly, it allows a variety of ways to manage your zonedata including
external to Chef, if necessary. See the "Zones" section below.

### Configuration

The has in `node['fb_bind']['config']` maps directly to `named.conf` syntax,
with the exception that you do not defined zone data here. Do not add a `zone`
or `zones` entry in this hash or the verifier will fail the run. The
`named.conf` template will use the data in `node['fb_bind']['zones']` to
generate the appropriate `zoone` stanzas.

Bind expects some configurations to be quoted and some to be note, and this
cookbook does a lot of work to get this right without you having to insert
quoted strings into your configuration. Generally speaking, just fill out the
hash in the most obvious way and this cookbook should generate a config with
the correct syntax.

In addition this cookbook will intelligently convert booleans to `no` and
`yes`, and we recommend you use booleans for boolean configurations.

As an example:

```ruby
{
  # move bind's working directory
  'directory' => '/mnt/dns_data',
  'auth-nxdomain' => false,
  'allow_update' => [ 'myacl' ];
  'version' => 'go away',
}.each do |key, val|
  node.default['fb_bind']['config']['options'][key] = val
end

{
  'acl myacl' => [ '1.2.3.4' ],
  'acl empty' => [ 'none' ],
}.each do |key, val|
  node.default['fb_bind']['config'][key] = val
end
```

Would generate a config like:

```text
acl myacl { 1.2.3.4; };
acl empty { none; };
options {
  directory "/mnt/dns_data";
  auth-nxdomain no;
  allow_update { myacl; }
  version "go away";
  # other default configs from this cookbook here
}
```

Note that the arguments to `directory` and `version` are properly quoted while,
the arguement to `allow_update` (`myacl`) is not.

#### Handling IPs nicely in configs: stable_resolve helper

By definition, bind needs IPs in lots of places. In many cases it may be
reasonable to hard-code IPs that are unlikely to change. In other cases you may
have a hosting provider you need to notify, and want to base this on hostnames
rather than IPs so that as their infrastructure changes, you automatically keep
up, but you don't want your DNS server to go down due to a DNS issue (cascading
failures are rough). To that end, this cookbook provides the `stable_resolve`
helper.

`stable_resolve` will attempt to resolve a hostname and return all IP addresses
associated with it, however if resolution fails, it will use it's cache to
return the last known set of IPs for that name. Further it will never resolve
the same name twice in a run no matter how often it is called. Here's an
example usage:

```ruby
{
  'primaries sample' => %w{
    axfr1.sample.com
    axfr2.sample.com
    axfr3.sample.com
    axfr4.sample.com
    axfr5.sample.com
  }.map { |x| FB::Bind.stable_resolve(x, node) }.flatten,
}.each do |key, val|
  node.default['fb_bind']['config'][key] = val
end

node.default['fb_bind']['config']['options']['also-notify'] = ['sample']
```

### Zone data

There are three ways this cookbook allows you to specify zone data:

* Directly in the node object - This is the default and what we recommend for
  most cases
* Via a flat file from another cookbook (i.e. `cookbook_file`) - Can be useful
  for transitions
* Completely separately - For environments where zone data is managed by a
  separate process

In the first two methods, the zonefiles will be validated using
`named-checkzone`, while if you use the third method, validating configurations
is left up to whatever system is writing the files.

#### Zone data in the node

The `node['fb_bind']['zones']` hash includes the basic config for the zone and,
optionally, the records themselves. Here's a simple example:

```ruby
node.default['fb_bind']['zones']['sample.conf'] = {
  'type' => 'primary',
  '_records' => {},
}
```

The `_records` hash is a human-usable name for the record pointing to a hash
for the record itself. Most record hashes have the following entries:

* `name` - Optional, defaults to `@`
* `class` - Optional, defaults to `IN`
* `type` - Type of record (`A`, `NS`, `AAAA`, etc.), will automatically be
  upcased for you, so make it whatever casing you want
* `ttl` - Optional, no default (not included in record of ommitted)
* `value` - The value of the record

Only SOA records deviate from this format. For SOA records, `value` is replaced
by `mname`, `rname`, `serial`, `refresh`, `retry`, `expire`, and
`negative-cache-ttl`, the 7 parts of an SOA record.

Finally, `ttl` can be specified as the `$TTL` line in the zonefile. If not
specified, it will default to `node['fb_bind']['default_zone_ttl']`.

Here's a more complete example:

```ruby
node.default['fb_bind']['zones']['sample.conf'] = {
  'type' => 'primary',
  '_records' => {
    'ttl' => 3600,
    'soa' => {
      'type' => 'SOA',
      'mname' => 'ns1.sample.com.',
      'rname' => 'hostnaster.ipom.com.',
      'serial' => '2025021500',
      'refresh' => '86400',
      'retry' => '43200',
      'expire' => '2419200',
      'negative-cache-ttl' => '3600',
    },
    'ns1' => {
      'type' => 'ns'
      'value' => 'ns1.sample.com',
    },
    'ns2' => {
      'type' => 'ns',
      'value' => 'ns2.sample.com',
    },
    'external ns' => {
      'type' => 'ns',
      'value' => 'ns1.sample-partner.com',
    },
    'root A' => {
      'type' => 'a',
      'value' => '192.168.1.2',
    },
    'www' => {
      'type' => 'a',
      'value' => '192.168.1.2',
    },
    'mx' => {
      'type' => 'mx',
      'ttl' => 300,
      'value' => '10 mail.sample.com',
    },
  },
}
```

```text
$TTL 3600
@               IN      SOA     ns1.sample.com. hostmaster.sample.com. (
                                2025021500      ; Serial
                                86400   ; Refresh
                                43200   ; Retry
                                2419200 ; Expire
                                3600    ; Negative Cache TTL
                )
@       IN  NS  ns1.sample.com
@       IN  NS  ns2.sample.com
@       IN  NS  ns1.sample-partner.com
@       IN  A   192.168.1.2
www     IN  A   192.168.1.2
@       IN  MX  10 mail.sample.com
```

If you'd like the human-readable keys to be inserted into the zonefile as
comments you can set `node['fb_bind']['include_record_comments_in_zonefiles']`
to `true` and it'll look like this:

```text
...
; ns1
@       IN  NS  ns1.sample.com
; ns2
@       IN  NS  ns2.sample.com
; external ns
@       IN  NS  ns1.sample-partner.com
; root A
@       IN  A   192.168.1.2
; www
www     IN  A   192.168.1.2
; MX
@       IN  MX  10 mail.sample.com
```

##### A note on TXT records

It's worth noting here that the handling of `TXT` records is special. You can
specify a txt record (like for DKIM keys) as long as you want and this cookbook
will appropriate chunk it into the proper 255-char sizes.

#### Zone data as a cookbookfile

If you prefer to manage your zones as flat files, you can specify them like
so:

```ruby
node.default['fb_bind']['zones']['sample.com'] => {
  'type' => 'primary',
  '_zonefile_cookbook' => 'mycookbook',
}
```

The files will be automatically installed to the system via `cookbook_file`.
The files **must** be named `db.$ZONE` (e.g. `db.sample.com`).

It is important that `fb_bind` install the files rather than your own
`cookbook_file`, as the files must be there early enough for the service to
start.

#### Zone data managed by an external process

If you specify `_filename` in the zone configuration, `fb_bind` will create
the correct `zone` stanza in `named.conf` and do nothing else. It will assume
some external process is managing the zones.

The `_filename` argument **should be a fully-qualified path**. Here is an
example in which you are using the same paths `fb_bind` does (at least on
Debian-like distributions), though doing that is not necessary.

```ruby
node.default['fb_bind']['zones']['sample.com'] => {
  'type' => 'primary',
  '_filename' => '/etc/bind/primary/db.sample.com',
}
```

If you decide to use the same paths as this cookbook, it is critical you name
the zonefiles `db.$ZONE` to prevent `fb_bind` from cleaning them up.

You can also put them elsewhere:

```ruby
node.default['fb_bind']['zones']['sample.com'] => {
  'type' => 'primary',
  '_filename' => '/mnt/dns_data/primary/db.sample.com',
}
```

### DNSSEC

DNSSEC is incredibly easily to enable. Simply set two keys on the zone:

```ruby
node.default['fb_bind']['zones']['sample.com'] => {
  'type' => 'primary',
  'dnssec-policy' => 'default',
  'inline-signing' => 'yes',
  '_records' => { ... }
}
```

Bind will dynamically create keys and sign the zones appopropriately without
you having to do anything else.

### Cleanup

This cookbook will cleanup files in its primary zonefile directory that it does
not own. It is for this reason, it uses a subdirectory of the config directory
called `primary`. It will intelligently handle the extra files created by
DNSSEC signed zonefiles and not remove thise files for zones it knows about
while also cleaning them up for zones it does not know about.

Optionally, you can set `node['fb_bind']['clean_config_dir']`, and `fb_bind`
will cleanup stray file from your configuration directory. A few things to note
here:

* Even though Redhat-like packages drop their config directly in `/etc`,
  this cookbook specifies `/etc/bind/named.conf` as the configuration file.
  This makes it much safer for us to cleanup the directory, when desired.
* We will intelligently exclude stuff like
  * Our 'primary' dir
  * The `keys-directory`
  * The `rndc.key` file

### Forcing empty RFC1918 zones

If you'd like to force that RC1918 zones are created and empty, you can set
`node['fb_bind']['empty_rfc1918_zones']` and will create valid empty zones for
them so that they cannot be used. This is often recommended for public servers.

### Packages

This cookbook will install the relevant packages and restart the service if
necessary. If you prefer to manage packages yourself, simpley set
`node['fb_bind']['manage_packages']` to `false`.

### Sysconfig

You can populate the hash in `node['fb_bind']['sysconfig']` to populate
variables for the Unit file. Use **lowercase** for keys, and we will upcase
them on generation of the file.

The unit files on different OSes are different, and we try to do some basic
verifiction relevant to your OS.

On Redhat-like OSes, we force the `NAMEDCONF` variable, which points to the
Bind's config file, and we ensure no `-c` options have been added into
`OPTIONS`, which would cause multiple `-c`s and fail startup.

### A word on terminology

This cookbook uses the newer terms 'primary' and 'secondary' for zone types
everywhere, including 'primaries' for lists of primary hosts for secondary
zones. The old keywords are supported in Bind9 as synonyms, but we default to
the current names.

See https://bind9.readthedocs.io/en/v9.18.14/chapter3.html for details.
