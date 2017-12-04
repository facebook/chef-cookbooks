fb_timers Cookbook
==================
A cookbook for generating systemd timer configs.

Requirements
------------
You must be running systemd in order to use this cookbook.

Attributes
----------
* node['fb_timers']['jobs'][$JOB_NAME]

Usage
-----
This cookbook is modeled after `fb_cron`, but designed to expose the power of
systemd timers natively.

Specify your timer jobs by adding a hash object under `node['fb_timers']['jobs']`

For example:

```
# Run a command every 15 minutes
node.default['fb_timers']['jobs']['my_custom_job'] = {
    'calendar' => FB::Systemd::Calendar.every(15).minutes,
    'command' => '/usr/local/bin/foobar.sh',
}

# More complex example with other fields you can set:
node.default['fb_timers']['jobs']['more_complex_job'] = {
    'calendar' => FB::Systemd::Calendar.every.weekday,
    'command' => '/usr/local/bin/foobar.sh thing1 thing2',
    'timeout' => '1d',
    'accuracy' => '1h',
    'persistent' => true,
    'splay' => '0.5h',
}
```

Specifying a periodic task in this way will create systemd timer and service units for your task, and configure them to run periodically based on the settings you provide.

### Fields
Required fields:

* `calendar`: A [systemd calendar spec](https://www.freedesktop.org/software/systemd/man/systemd.time.html) for when you want your job to run. Corresponds to the `OnCalendar` field of the systemd timer. See below for helpers to generate common calendar patterns.
* `command`: The command to run. Corresponds to the `ExecStart` field of the systemd service.

Optional fields:

* `timeout`: How long to allow the command to run before it is stopped forcefully. A value of 0 disables the timeout and allows the command to run indefinitely. Corresponds to the `TimeoutSec` field of the systemd timer. (defaults to `0s`)
* `accuracy`: systemd will attempt to group periodic tasks according to their calendar fields within their accuracy. Specifying a low accuracy forces systemd to run your task at the specified, giving systemd less control over when your service is run. Corresponds to the `AccuracySec` field of the systemd timer. (defaults to `1s`)
* `persistent`: Whether or not the job should run immediately if a run is missed (e.g. due to the system being powered off) rather than waiting until the next time the `calendar` field specifies. Corresponds to the `Persistent` field of the systemd timer. (defaults to false) Note that this is different from running on startup.
* `splay`: Maximum random time to wait before executing the task. A value of 0 disables this behavior. Corresponds to the field `RandomizedDelaySec` in (defaults to `0s`)
* `syslog`: Whether or not to enable syslog for this service. A value of true sets `StandardOutput` to `syslog` and `SyslogIdentifier` to the name of your job.
* `only_if`: Specify a Proc which will be evaluated at runtime and used to gate whether the timer is setup.  Especially useful if you need to gate on a chef API value.  E.g.: 'only_if' => proc { conditional }

Advanced fields:

**WARNING**: These fields shouldn't be used unless you know what you're doing and have a very good reason. Come talk to the OS team if you have a legit use-case and we can figure out if we want to make a more standard option for whatever you're doing.

* `service_options`: Additional options to include in the `[Service]` section of the service unit file.
* `service_unit_options`: Additional options to include in the `[Unit]` section of the service unit file.
* `timer_options`: Additional options to include in the timer unit file.
* `autostart`: Setting this to false will prevent units from being enabled and started in the chef run.  This can be used for creating user units which are managed by other means. (defaults to `True`)

### Common Calendar Patterns
A helper library is provided to allow easy generation of [systemd calendar specs](https://www.freedesktop.org/software/systemd/man/systemd.time.html) with chef. It can be used by invoking `FB::Systemd::Calendar.every` in a variety of different ways:

* `FB::Systemd::Calendar.every(15).minutes` - Runs every 15 minutes.
* `FB::Systemd::Calendar.every(4).hours` - Runs every 4 hours.
* `FB::Systemd::Calendar.every.weekday` - Runs once a day, excluding Saturday and Sunday.
* `FB::Systemd::Calendar.every.week` - Runs once a week.
* `FB::Systemd::Calendar.every.month` - Runs once a month.

Each of these methods returns a string representation of a systemd calendar spec.

For example, this usage, which runs a shell script every 15 minutes:

```
node.default['fb_timers']['jobs']['my_custom_job'] = {
    'calendar' => FB::Systemd::Calendar.every(15).minutes,
    'command' => '/usr/local/bin/foobar.sh',
}
```

is equivalent to this config, which uses the systemd calendar spec directly:

```
node.default['fb_timers']['jobs']['my_custom_job'] = {
    'calendar' => '*:0/15:0',
    'command' => '/usr/local/bin/foobar.sh',
}
```

More complex time specs can be defined using the [systemd calendar spec](https://www.freedesktop.org/software/systemd/man/systemd.time.html).

### More Info About Systemd Timers

For more information about systemd timers read the
[internal wiki page](https://our.intern.facebook.com/intern/wiki/OS/CentOS7/Systemd/Timers/)
or [the public man page](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
