fb_system_upgrade Cookbook
==========================

Requirements
------------

Attributes
----------
* node['fb_system_upgrade']['allow_downgrades']
* node['fb_system_upgrade']['early_upgrade_packages']
* node['fb_system_upgrade']['early_remove_packages']
* node['fb_system_upgrade']['exclude_packages']
* node['fb_system_upgrade']['failure_callback_method']
* node['fb_system_upgrade']['log']
* node['fb_system_upgrade']['notify_resources']
* node['fb_system_upgrade']['repos']
* node['fb_system_upgrade']['success_callback_method']
* node['fb_system_upgrade']['timeout']
* node['fb_system_upgrade']['wrapper']

Usage
-----
This cookbook provides a pluggable framework for managing system upgrades.

### FB::SystemUpgrade
The following methods are available:

* `FB::SystemUpgrade.get_upgrade_command(node)`
  Return the command that will be used to execute the system upgrade.

### Upgrade command generation
At its core, this cookbook provides a controlled way to run a system upgrade
via a `dnf upgrade -y` or similar command. The actual command used is generated
by `FB::SystemUpgrade.get_upgrade_command(node)` and is controlled by several
attributes:

* `node['fb_system_upgrade']['wrapper']` by default wraps the command with
  `nice` and `ionice` to reduce its impact on a running system
* `node['fb_system_upgrade']['log']` is where the command output and the
  upgrade process is logged (defaults to
  `/var/chef/outputs/system_upgrade.log`)
* `node['fb_system_upgrade']['repos']` is the set of repositories that should
  be enabled to upgrade the system; if this attribute is set, all repositories
  are disabled except for the ones in this list during the upgrade
* `node['fb_system_upgrade']['exclude_packages']` is a set of packages that
  should be excluded from being upgraded
* `node['fb_system_upgrade']['allow_downgrades']` controls whether the upgrade
  should just go forward (the default) or also allow downgrading and erasing
  packages; this can be useful when switching between major releases, but
  depending on the state of the repos it could also easily result in a broken
  system, so care is recommended

### System upgrade flow
The upgrade itself is handled by the `fb_system_upgrade` custom resource, which
operates in roughly like this:

* if `node['fb_system_upgrade']['early_upgrade_packages']` is set, upgrade all
  the packages in the list
* if `node['fb_system_upgrade']['early_remove_packages']` is set, remove all
  the packages in the list
* generate the upgrade command as described above
* execute the upgrade
  * run the upgrade command with a timeout from
  `node['fb_system_upgrade']['timeout']` (defaulting to 30 minutes)
  * call any callback methods that were defined for success/failure in
    `node['fb_system_upgrade']['success_callback_method']` and
    `node['fb_system_upgrade']['failure_callback_method']`
  * notify any resources that were defined in
    `node['fb_system_upgrade']['notify_resources']`

### Callbacks
Two attributes are provided to define callback methods that should be called
after the upgrade:

* `node['fb_system_upgrade']['success_callback_method']` for a successful
  upgrade; note that any exceptions potentially raised by this method will be
  swallowed
* `node['fb_system_upgrade']['failure_callback_method']` for a failed upgrade

Both of the callbacks should take the `node` as their only argument.

### Notifications
At the end of the upgrade, `fb_system_upgrade` will file off notifications to
any resources listed in `node['fb_system_upgrade']['notify_resources']`. This
is a `Hash` in the `resource` => `action` format. For example, setting:

```ruby
node.default['fb_system_upgrade']['notify_resources'] = {
   'file[/system-upgrade-flag-file]' => :create,
}
```

will result in a

```
notifies :create, 'file[/system-upgrade-flag-file]'
```

being issued at the end of the upgrade. Note that it's up to you to ensure that
the resource being notified is appropriately defined in the resource
collection.
