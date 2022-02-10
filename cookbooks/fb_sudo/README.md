fb_sudo Cookbook
================
This cookbook installs sudo and provides an API to configure it.

Requirements
------------

Attributes
----------
* node['fb_sudo']['aliases']
* node['fb_sudo']['aliases']['host']
* node['fb_sudo']['aliases']['host'][$ALIAS]
* node['fb_sudo']['aliases']['user']
* node['fb_sudo']['aliases']['user'][$ALIAS]
* node['fb_sudo']['aliases']['command']
* node['fb_sudo']['aliases']['command'][$ALIAS]
* node['fb_sudo']['aliases']['runas']
* node['fb_sudo']['aliases']['runas'][$ALIAS]
* node['fb_sudo']['defaults'][$SETTING]
* node['fb_sudo']['default_overrides'][$OVERRIDE]
* node['fb_sudo']['manage_packages']
* node['fb_sudo']['users'][$USER]

Usage
-----
Include `fb_sudo` to install sudo. By default users in the `sudo` group will
be granted full access. Additional rules can be setup using
`node['fb_sudo']['users']`.

### Defaults
Defaults is probably the most interesting part of the API. It's a hash where the
value is either bool or a string. If it's a bool then the default will be
represented as `key` or `!key` as appropriate. If it's a string, then it will
represented as `key=val`. E.g.

```ruby
node.default['fb_sudo']['defaults']['timestamp_type'] = 'global'
node.default['fb_sudo']['defaults']['env_reset'] = true
```

Would result in the following values being added to Defaults:

```text
timestamp_type=global,env_reset
```

The defaults correlate to the RHEL defaults.

Default overrides can be specified using `default_overrides` like so:

```ruby
node.default['fb_sudo']['defaults']['log_output'] = true
node.default['fb_sudo']['default_overrides']['!/usr/bin/sudoreplay'] =
  '!log_output'
```

which renders like this:

```text
Defaults log_output
Defaults!/usr/bin/sudoreplay !log_output
```

### Aliases
This is the thinnest wrapper possible. Simply add aliases as you would in
`/etc/sudoers`, but don't worry about upcasing alias names, we do that for you:

```ruby
node.default['fb_sudo']['aliases']['command']['printing'] = '/usr/sbin/lpc, /usr/bin/lprm'
```

Will render as:

```text
Cmnd_Alias PRINTING = /usr/sbin/lpc, /usr/bin/lprm
```

We recommend keeping alias names as all-lower-case for easier typing and
predictably modifying later in the runlist.

### Users
Users work similar to Aliases, but with an additional level of hashing
so you can have multiple entries:

```ruby
node.default['fb_sudo']['users']['johnsmith'] = {
  'all the stuff' => 'ALL=ALL ALL'
  'some passwordleess stuff' => 'ALL=ALL NOPASSWD: /sbin/reboot',
}
```

To have a better management on sudo commands, command should be added with
the maintain oncall team and the reason why you need add this command to sudoers.

Usage
node.default['fb_sudo']['users'][$USER][description][oncall_team][reason] = (
  [list of commands]
)

The commands will be added in the /etc/sudoers as following.

```text
# User
## <description>
### Oncall <oncall_team1>
$USER ALL=ALL NOPASSWD: <your lists of commands>
### Oncall <oncall_team2>
$USER ALL=ALL NOPASSWD: <your lists of commands>
```

```ruby
node.default['fb_sudo']['users']['oliviajindi']['test sudo']['ssh_infra'] = {
  'reboot service' => ['/sbin/reboot'],
  'reason for adding new commands'] => ['command1', 'command2']
}
```

For this example, the commands will be added as

```text
# User
## test sudo
### Oncall ssh_infra
oliviajindi ALL=ALL NOPASSWD: '/sbin/reboot', command1, command2
```

### Packages
By default this cookbook keeps the sudo package up-to-date, but if you
want to manage them locally, simply set
`node['fb_sudo']['manage_packages']` to false.
