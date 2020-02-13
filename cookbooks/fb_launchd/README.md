fb_launchd Cookbook
=========================
This cookbook is similar to `fb_timers`. It manages launchd resources that
describe scheduled or cron-like actions - e.g. those that run a program at a
defined time. For persistent daemons/services, define your resource explicitly
in terms of Chef `launchd` or `service` resources.

Requirements
------------
This cookbook only works on macOS (which is the only platform where launchd
itself is supported).

Attributes
----------
* node['fb_launchd']['jobs'][$JOB]
* node['fb_launchd']['prefix']

Usage
-----
Include this recipe and add any launchd items you want to setup to the
`node['fb_launchd']['jobs']` attribute. Use the item label as key, and see
the [launchd resource](https://docs.chef.io/resource_launchd.html) for supported
values; at a minimum, you'll want to set `program_arguments` to define what's
going to be run. Note that the `label` and `key` properties are not supported by
`fb_launchd`. Example:

```ruby
node.default['fb_launchd']['jobs']['chefctl'] = {
  'program_arguments' => ['/opt/scripts/chef/chefctl.sh'],
  'run_at_load' => true,
  'start_interval' => 1800,
  'time_out' => 600
}
```

The name of your job must not contain the prefix. If you pass in the prefix into
the job label, fb_launchd will fail:

```
fb_launchd: Your label com.facebook.chef.chefctl must not contain the prefix
already. Ex: node.default['fb_launchd']['jobs']['myservice']
```

To make the launchd service definition conditional, add the optional 'only_if'
attribute, and set it to a proc that will be evaluated by the resource at
runtime:

```ruby
node.default['fb_launchd']['jobs']['chefctl'] = {
  'only_if' => proc { boolean_expression },
  ...
}
```

**NOTE**: You should override the default value of the
`node['fb_launchd']['prefix']` attribute in a recipe (e.g. your custom init
recipe). If you do not do this, `fb_launchd` will assume a label prefix of
`com.facebook.chef`.
