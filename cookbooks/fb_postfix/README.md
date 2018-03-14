fb_postfix Cookbook
====================
This cookbook configures postfix. Do not make custom changes in this cookbook.
Instead manipulate the provided attributes in your role or tier-specific
cookbook.

Requirements
------------

Attributes
----------
* node['fb_postfix']['enable']
* node['fb_postfix']['main.cf']
* node['fb_postfix']['master.cf'][\$SERVICE][\$TYPE]
* node['fb_postfix']['aliases']
* node['fb_postfix']['localdomains']
* node['fb_postfix']['mynetworks']
* node['fb_postfix']['relaydomains']
* node['fb_postfix']['access']
* node['fb_postfix']['canonical']
* node['fb_postfix']['etrn_access']
* node['fb_postfix']['local_access']
* node['fb_postfix']['sasl_auth']
* node['fb_postfix']['sasl_passwd']
* node['fb_postfix']['transport']
* node['fb_postfix']['virtual']
* node['fb_postfix']['custom_headers']

Usage
-----
This recipe is included in the base role, but certain nodes must not have
postfix running (such as MTAs). To exclude a node from running postfix, set
`node['fb_postfix']['enable']` to false. This will still install
postfix, but will ensure postfix is stopped and disabled.

This cookbook supports several config files in `/etc/postfix` driven by the
attributes listed above. They are grouped by different formatting and handling
requirements listed below.

### main.cf
Key/value pairs in this hash will generate lines in the `main.cf` config file. 
You can add or change items by adding to or changing an item in the hash. To 
remove a default item, set the value to `nil` and the template will leave it 
out. Restart of postfix on changes happens automatically.

For example you might do:

```
node.default['fb_postfix']['main.cf']['command_time_limit'] = '300s'
```

### Aliases
Like `main.cf`, the aliases hash will render key/value pairs into the 
appropriate format in the config file. There are no defaults. On any changes, 
Chef will automatically rerun `postalias` to regenerate the `aliases.db` file 
and restart postfix.

### localdomains, mynetworks, relaydomains
Each of these attributes take an array which you can manipulate. The contents
of the array are rendered one element per line in the file and postfix will be
automatically restarted if there are changes.

### Maps
This covers `access`, `canonical`, `etrn_access`, `local_access`, `sasl_auth`, 
`sasl_passwd`, `transport` and `virtual`. Each of these attributes takes a hash
similar to `aliases`. Chef will automatically run `postmap` to regenerate the 
appropriate `.db` file and restart postfix if there are changes.

### Master.cf
It's not common to need to change `master.cf`, but if you need to the 
`master.cf` key in the hash will give you full access to do so.

The keys are services (like `smtp`), the next key is type (like `unix` or
`inet`), and then the hash below that is the settings in 
[master(5)](http://www.postfix.org/master.5.html) available for each entry.

For example, to configure postfix to not send bounce notifications, you might 
do:

```
node.default['fb_postfix']['master.cf']['bounce']['unix']['command'] = 'discard'
```

### Tweaking headers

Use this to update headers. See [header_checks](http://www.postfix.org/header_checks.5.html) for details.

For example, to add a new header:
```
node.default['fb_postfix']['custom_headers']['some description'] = {
  'regexp' => '/^To:/',  # match this existing header
  'action' => 'PREPEND',  # and prepend new header
  'header' => 'Some-New-Header', # header name
  'value' => Some_Value',  # with this value
}
```
*Note*: In `main.cf`, `header_checks` is by default pointed to  
`/etc/postfix/custom_headers.regexp`.
