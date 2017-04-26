fb_iptables Cookbook
====================
Basic cookbook to emit iptables rules. Only supports mangle/filter/raw
tables since those are the only one supported by fb's kernel.

Every rule is automatically added to both ipv4 and ipv6 tables unless
you specify so (in case you want to filter on specific ip
addresses/block)

If you need to modify IPTables rules outside of Chef, please see `Dynamic
Chains` section.

Requirements
------------

Attributes
----------
* node['fb_iptables']['enable']
* node['fb_iptables']['manage_packages']
* node['fb_iptables']['sysconfig'][$KEY]
* node['fb_iptables'][$TABLE][$CHAIN]['policy']
* node['fb_iptables'][$TABLE][$CHAIN]['rules'][$RULE_NAME]['ip']
* node['fb_iptables'][$TABLE][$CHAIN]['rules'][$RULE_NAME]['rule']
* node['fb_iptables'][$TABLE][$CHAIN]['rules'][$RULE_NAME]['rules']
* node['fb_iptables']['dynamic_chains'][$TABLE][$YOUR_CHAIN]

Usage
-----
Include `fb_iptables` to manage iptables on a machine. By default, the cookbook
will manage the iptables packages; this can be opted out of by setting
`node['fb_iptables']['manage_packages']`. The iptables service itself is
disabled by default; to enable it set `node['fb_iptables']['enable']` to true.

### Nomenclature
The nomenclature for iptables is often confused, and we use the definitions used
by the IPTables code, base which are as follows:

* `tables` are `filter`, `mangle`, and `raw`.
* `chains` are lists of rules within a table such as `INPUT`, `OUTPUT`,
  `PREROUTING` or any custom ones you choose to make.

### Default Policies
You can specify a default policy for a built-in chain for when no rules match
using `node['fb_iptables'][$TABLE][$CHAIN]['policy']`. They are a target such as
`ACCEPT`, `DROP`, etc. See iptables documentation for details.

### Rules
The "name" of a rule is arbitrary, it's simply there so it can be
modified/reference later in the run if you choose.

Each rule has the following components:
* `ip` - this is the IP version (4 or 6)
* `rule` - the actual rule (such as `-s 10.1.1.1/24 -j DROP`) - note that
  specifying the table/chain (`-t` and `-A`) is not needed (and cannot be) here.
* `rules` - Instead of a single rule, you can specify an array to `rules`.

### A warning about ordering and policies
As with regular iptables, ordering matters here. The rules will be
evaluated in the orders they are set in the cookbook. Please keep that
in mind at all time, especially when implementing a complex ruleset.

As with regular iptables, you can choose between denying everything
using chain policy, then add rules to allow certain packets or
allowing everything then dropping certain packets. Any fancier usage
pattern you might want to use is at your own risk. Please also keep in
mind this is a system-wide choice: you might want to check that this
choice hasn't already been made by a previous cookbook.

### fb_iptables in 10 lines
Include the recipe in your own and update rules attributes.

```ruby
include_recipe 'fb_iptables'

node.default['fb_iptables']['filter']['INPUT']['policy'] = 'DROP'
node.default['fb_iptables']['filter']['INPUT']['rules']['rule_name'] = {
    # Rules are ipv4/v6 by default.
    'rule' => '-p tcp --dport 22 -j ACCEPT'
}
node.default['fb_iptables']['filter']['INPUT']['rules']['ipv4_rule'] = {
    'ip' => 4, # Make the rule ipv4 only
    'rule' => '-p tcp -s 192.168.0.1 -j ACCEPT'
}
```

### Dynamic Chains
`fb_iptables` provides the functionality to shunt to custom chains which are
controlled outside of Chef (e.g. by a local daemon). You must register such a
chain and where you'd like to shunt from. For example, if you have a special
firewall that you configure to put all its inbound filters into `my_filters`,
then you could do:

```ruby
node.default['fb_iptables']['dynamic_chains']['filter']['my_filters'] = [
  'INPUT',
]
```

This will:
* Ensure the chain `my_filters` always exists
* Have the first rule in `INPUT` always jump to `my_filters`
* Never erase that chain on a reload

**NOTE**: If the dynamic chain has a match, control will not return to the
primary chain... but if no match is found, controll will return to the primary
chain.

**NOTE**: Dynamic chains are saved before reload and then restored after which
means there is a slight race condition - if an update happens to it in the
middle of a reload, it could be lost.

### Sysconfig
The config files in `/etc/sysconfig/iptables` and `/etc/sysconfig/ip6tables` can
be configured using `node['fb_iptables']['sysconfig']`. This hash will be
translated to key-value pairs in the config file. The keys will automatically be
upper-cased and prefixed with `IPTABLES_` or `IP6TABLES_` as necessary. For
example:

```
node.default['fb_iptables']['sysconfig']['modules'] = 'nat'
```

would translate to:

```
IPTABLES_MODULES="nat"
```

and:

```
IP6TABLES_MODULES="nat"
```

### Reload triggers
You can subscribe to `execute[reload iptables]` and `execute[reload ip6tables]`
if you need to trigger on rules reloading.

### Unsupported features
The `nat` and `security` tables are not currently supported.

User defined table are not supported.
