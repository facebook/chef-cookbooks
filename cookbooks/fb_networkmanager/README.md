fb_networkmanager Cookbook
============================
An attribute-driven API to configure Network Manager

Requirements
------------

Attributes
----------
* node['fb_networkmanager']['enable']
* node['fb_networkmanager']['system_connections']
* node['fb_networkmanager']['system_connections'][$NAME]['_migrate_from']
* node['fb_networkmanager']['system_connections'][$NAME]['_defaults']
* node['fb_networkmanager']['config']

Usage
-----
### Config

The global config (`/etc/NetworkManager/NetworkManager.conf`), is controlled
by the `config` hash. It's a two-level hash where the top-level is INI section
names and the second level is key-value pairs for the options in that section.

For example:

```ruby
node.default['fb_networkmanager']['config']['main']['foo'] = 'bar'
```

would render as:

```text
[main]
foo=bar
```

The default config is based on the Ubuntu config but should be safe for all
distros.

### System Connections

Network Manager unfortunately uses the files in the `system-connections` folder
as a data store about those networks. This means they can change out from under
you as it addds its own information. For example, for WiFi entries, it can add
BSSIDs it has seen to the file.

As such using the desired config to populate a template is not sufficient - this
would both lose data that Network Manager wants and also cause a lot of
unnecessary resource firing.

To work around this scenario, this cookbook loads in the existing file, merges
in the desired config, and then checks to see if the resulting contents are
different from just the loaded file. If the values would not change, then we do
not write out the new config. If the values are different, then we write out
the merged config. Since Network Manager can write out values in a different
order or with different spacing, we dont' compare the actual files, but instead
the parsed data. We leverage IniParse for reading and writing INI files since
it is bundled with Chef.

All that said, the system_connections hash works a lot like the `config` hash,
except there's an extra level for each connection. For example:

```ruby
node.default['fb_networkmanager']['system-connections']['mywifi'] = {
  'connection' => {
    'type' => 'wifi',
    'id' => 'Cool Wifi',
    'uuid' => '...',
  },
  'wifi' => {
    'mode' => 'infrastructure',
    'ssid' => 'Cool Wifi',
  },
  'wifi-security' => {
    'auth-alg' => 'open',
    'key-mgmt' => 'wpa-psk',
    'psk' => 'SuperS3kr1t',
  },
}
```

Would create `/etc/NetworkManager/system-connections/fb_networkmanager_mywifi`
with this content:

```text
[connection]
id=Cool Wifi
uuid=...
type=wifi

[wifi]
mode=infrastructure
ssid=Cool Wifi

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=SuperS3kr1t
```

Note that all files we make are prefixed with `fb_networkmanager`, so that we
can cleanup files we created that are no longer in the config.

### A note on booleans

It is worth noting that various plugins and parts of the config expect
different kinds of booleans - some `true` and `false`, others `yes` and `no`.
Normally, an FB Attribute API cookbook would take a true ruby boolean and
convert it to the appropriate string for a system, but since it's not
consistent across NM, we leave it to the user to specify the right one for the
right value. This is true both in `config` and in `system_connections`.

### A note on UUIDs

We generally recommend coming up with a static UUID per connection you want
to rollout. For example, generate a UUID (for example using `uuidgen`, or
by `cat /proc/sys/kernel/random/uuid`), and then associate that with given
connection, statically in your config. You must use a different UUID for each
connection (obviously), but using the same UUID for the same connection across
machines makes debugging easier.

However, if you want truly unique UUIDs, one option is to just not specify a
UUID and let Network Manager fill one in. However, not all versions of NM
support this, and some will just ignore that connections.

You can't just generate UUIDs in the recipe, as they'll change on every run. So
here's one way to solve that problem: build each UUID seeded with the hostname
and the connection name so they stay the same across runs:

```ruby
node.default['fb_networkmanager']['system-connections']['mywifi'] = {
  'connection' => {
    'type' => 'wifi',
    'id' => 'Cool Wifi',
    'uuid' => UUIDTools::UUID.sha1_create(
      UUIDTools::UUID_DNS_NAMESPACE,
      "#{node['fqdn']}/Cool Wifi",
    ),
  },
  ...
}
```

#### Migrating from existing configs

Migrating to this cookbook could potentially pose a problem: you want all the
information from the existing connection, but you don't want a duplicate
connection.

We provide a `_migrate_from` key. When populated, we'll use that as our base
config the first time, merge any data provided in the node, and then delete
the old config.

This provides seemless transition - it will preserve the UUID, which will
keep network manager from thinking any connections went away, and ensure
in-use connections don't drop.

For example, let's say you had droped a file
`/etc/NetworkManager/system-connections/OurCorpWifi` that you had dropped off
with `cookbook_file`, or a script, or even that you had was built through
manually setting it up in the NM GUI. You could then do:

```ruby
node.default['fb_networkmanager']['system-connections']['our_corp_wifi'] = {
  '_migrate_from' => 'OurCorpWifi',
  'connection' => {
    'type' => 'wifi',
    'id' => 'OurCorpWifi',
  },
  'wifi' => {
    'mode' => 'infrastructure',
    'ssid' => 'OurCorpWifi',
  },
  'wifi-security' => {
    'auth-alg' => 'open',
    'key-mgmt' => 'wpa-psk',
    'psk' => 'SuperS3kr1t',
  },
}
```

Then anything not specified here will be pulled in from the existing
`OurCorpWifi` file. Note that any settings that you care about should be
specified in the node to ensure that on new setups, you're not missing critical
configuration.

Note that if the original service file isn't there, Chef will just create a new
connection file (though it will warn). Also note that once Chef has created one,
it stop pulling in the old file (and will remove it).

#### Providing defaults

In general, the Chef config wins over the user config as described above.
However it is often desirable to specify a default config in case the user does
not specify anything. In that case you can use the `_defaults`. For example:

```ruby
node.default['fb_networkmanager']['system-connections']['our_corp_wifi'] = {
  '_migrate_from' => 'OurCorpWifi',
  '_defaults' => {
    'connection' => {
      'autoconnect-priority' => '100',
    }
  },
  'connection' => {
    'type' => 'wifi',
    'id' => 'OurCorpWifi',
  },
  'wifi' => {
    'mode' => 'infrastructure',
    'ssid' => 'OurCorpWifi',
  },
  'wifi-security' => {
    'auth-alg' => 'open',
    'key-mgmt' => 'wpa-psk',
    'psk' => 'SuperS3kr1t',
  },
}
```

The rendered config here will set `connection.autoconnect-priority` to 100
if there is no value for it found in the existing file, but will use the value
in the file if it exists. The logic here is quite simple:

  defaults < user config < chef config
