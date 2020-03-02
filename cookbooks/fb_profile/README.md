fb_profile Cookbook
===================

Requirements
------------

Attributes
----------
* node['fb_profile']['early_entries']
* node['fb_profile']['aliases']
* node['fb_profile']['variables']
* node['fb_profile']['late_entries']

Usage
-----
This generates a file in `/etc/profile.d`, which means that what
you put in here should be bourne-shell compatible. It also means
it's only loaded once at login, not on each terminal you open.

### Aliases

This is a simple hash of alias to command. Ala:

```ruby
node.default['fb_profile']['aliases']['ll'] = 'ls -l'
```

### Variables

This is a straight forward mapping of variables:

```ruby
node.default['fb_profile']['variables']['EDITOR'] = 'vim'
```

All variables are `export`ed.

### Early and Late entries
These are wholesale entries that are put at the beginning or end of the file.
It is recommended you used heredocs with them like so:

```ruby
node.default['fb_profile']['early_entries']['my cool thing'] = << ~EOF
  if [ "$FOO" = 'yes' ]; then
    # do a thing here
  fi
EOF
```
