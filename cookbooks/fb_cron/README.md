fb_cron Cookbook
====================
This cookbook provides a simple data-based API for setting crons and configuring
the anacrontab environment.

YOU SHOULD NOT BE SETTING YOUR TIER'S CRON JOBS IN THIS COOKBOOK!

Requirements
------------

Attributes
----------
* node['fb_cron']['environment'][$NAME][$VALUE]
* node['fb_cron']['jobs'][$NAME]['command']
* node['fb_cron']['jobs'][$NAME]['comment']
* node['fb_cron']['jobs'][$NAME]['time']
* node['fb_cron']['jobs'][$NAME]['user']
* node['fb_cron']['jobs'][$NAME]['only_if']
* node['fb_cron']['jobs'][$NAME]['splaysecs']
* node['fb_cron']['jobs'][$NAME]['exclusive']
* node['fb_cron']['anacrontab']['environment']['$SETTING']
* node['fb_cron']['cron_allow']
* node['fb_cron']['cron_deny']
* node['fb_cron']['manage_packages']

Usage
-----

### Adding Jobs
`node['fb_cron']['jobs']` is a hash of crons. To add a job, simply do:

```ruby
node.default['fb_cron']['jobs']['do_this_thing'] = {
  'time' => '4 5 * * *',
  'user' => 'apache',
  'command' => '/var/www/scripts/foo.php',
}
```

PLEASE NAME YOUR CRONJOB AS FOLLOWS:
* simple string
* no spaces
* underscores instead of dashes

You can also specify 'mailto' to direct mail for your job.

See 'Removing Jobs' for details.

'user' is optional and will default to 'root', but 'time' and 'command'
are required.

#### only_if
Any cron entry can include an `only_if` that *must* be a `proc`. It will
be evaluated at runtime and the job will not be included if the only_if does
not evaluate to true. For example:

```ruby
node.default['fb_cron']['jobs']['do_this_thing'] = {
  'only_if' => proc { node['fb_bla']['enabled'] }
  'time' => '4 5 * * *',
  'user' => 'apache',
  'command' => '/var/www/scripts/foo.php',
}
```

#### comment
The comment entry of the job, which defaults to the job name.

### splaysecs
Defaults to false/none.  Please set a splay time for your cronjob, or
explicitly set this to false to indicate that your job can't tolerate a splay.
A bunch of cronjobs kicking off at exactly the same time can impact CPU, power,
and network resources even if each of them are very small.

### exclusive
Defaults to false/none.  Ensures that only one instance of this job is running,
based on a lockfile. If true, a lockfile is determined from the job name.

### Removing Jobs
To remove a job you added, simply stop adding it to the hash.  This cookbook
makes cron idempotent *as a whole*, thus if you remove the lines adding a cron
job, it'll be removed from any systems it was on.

A bunch of default crons we want everywhere are set in the attributes file, if
you need to exempt yourself from one, you can simply remove it from the hash:

```ruby
node.default['fb_cron']['jobs'].delete('do_this_thing')
```

For this reason, cron jobs should be given simple names as described above
to make exempting systems easy.

NOTE: These jobs will end up in /etc/cron.d/fb_crontab
WARNING: This cookbook wipes out /var/spool/cron/root

### Changing environment options
If your system supports it, you can use `node['fb_cron']['environment']` to
affect the environment of the init script. On Redhat-like systems these
variables go into `/etc/sysconfig/crond`, on Debian-like systems these go to
`/etc/default/cron`. For example:

```ruby
# For RH
node.default['fb_cron']['environment']['CRONDARGS'] = "-s"
# For Debian
node.default['fb_cron']['environment']['EXTRA_ARGS'] = "-s"
```

### anacrontab configuration
Anacron provides a mechanism for configuring the environment used in anacron job
execution. This can be configured using the
`node['fb_cron']['anacrontab']['environment']` attribute, as described in the
[anacrontab](https://linux.die.net/man/5/anacrontab) documentation. For example,
to modify the start time of anacron jobs from the default 3-22 o'clock to 6-8
o'clock (server time):

```ruby
node.default['fb_cron']['anacrontab']['environment']['start_hours_range'] = '6-8'
```

NOTE: This is currently only implemented on Redhat-like OSes.

### configuring who can run crontab command
Use the `node['fb_cron']['cron_allow']` and `node['fb_cron']['cron_deny']`
attributes to control the content of the `/etc/cron.allow` and `/etc/cron.deny`
files. The attributes default to empty arrays, and the files will be removed if
they remain empty arrays. Simply append to them:

```ruby
node.default['fb_cron']['cron_allow'] << 'user1'
```

This can be used for compliance with security benchmarks.

### Packages
By default this cookbook keeps the cron package up-to-date, but if you
want to manage them locally, simply set
`node['fb_cron']['manage_packages']` to false.
