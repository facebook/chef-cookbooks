fb_motd Cookbook
====================
This cookbook generates the Message of the Day file (/etc/motd)

Requirements
------------

Attributes
----------
* node['fb_motd']['extra_lines']
* node['fb_motd']['motd_news']['enabled']
* node['fb_motd']['motd_news']['urls']
* node['fb_motd']['motd_news']['wait']
* node['fb_motd']['motd_news'][$KEY]
* node['fb_motd']['update_motd']['enabled']
* node['fb_motd']['update_motd']['whitelist']
* node['fb_motd']['update_motd']['blacklist']

Usage
-----
To add anything to the /etc/motd file, simply add lines to this array:

```ruby
node['fb_motd']['extra_lines']
```

### Ubuntu extensions

We support two Ubuntu extensions to motd: `motd_news` and `update_motd`.

#### motd_news

`motd_news` allows `pam_motd` to dynamically retrieve news from a URL and
display it along with the motd. You can enable/disable this with
`node['fb_motd']['motd_news']['enabled']`. The `urls` key is an array of URLs
and the default is `https://motd.ubuntu.com` which is the default Ubuntu
provides. `wait` is simply the max number of seconds before timing out. Note
that any key can be added to this array and it will be added to
`/etc/default/motd-news`. These three were the meaninful ones at time of
writing.

#### update_motd

`update_motd` is a directory of scripts run with `run-parts` whose output make
up the motd you see when you login. The whole thing can be disabled by setting
`enabled` to `false`.

If it is enabled, then we choose which scripts to enable/disable using
`whitelist` and `blacklist`. If a list is empty then it is not considered (in
other words, if you don't want to use a whitelist, leave it empty, you don't
have to populate it with everything).

If both whitelist and blacklist are in use then blacklisting will win (i.e. is
evaluated last). So for example given the follow scripts: `00-a 00-b 00-c
00-d`, if you had:

```ruby
node.default['fb_motd']['update_motd']['whitelist'] = ['00-a', '00-c']
node.default['fb_motd']['update_motd']['blacklist'] = ['00-c']
```

Then the only script to be enabled would be `00-a`.

Scripts are enabled/disabled by toggling the executable bit on them.
