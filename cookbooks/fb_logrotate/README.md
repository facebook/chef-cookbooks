fb_logrotate Cookbook
====================
This configures the logrotate package with common configs that go on
every server, but do not necessarily have a corresponding cookbook
they should go in.

If the system that this cookbook is run on is MAC OS X, it will populate all
the files outlined in the configration in the newsylog.d format.

See http://www.freebsd.org/cgi/man.cgi?query=newsyslog.conf
for more details about the newsyslog feature.

Requirements
------------

Attributes
----------
* node['fb_logrotate']['globals'][$CONFIG]
* node['fb_logrotate']['configs'][$NAME]
* node['fb_logrotate']['add_locking_to_logrotate']
* node['fb_logrotate']['debug_log']
* node['fb_logrotate']['systemd_timer']
* node['fb_logrotate']['timer_settings']

Usage
-----
The configuration of logrotate via Chef is best explained by looking
directly at attributes/default.rb of this cookbook. A summary is below.

The `node['fb_logrotate']['configs']` hash contains one entry
per logrotate configuration block.

To rotate a new set of logs, add a new entry to this hash, like so:

```
node.default['fb_logrotate']['configs']['myapp'] = {
  'files' => ['/var/log/myapp.log'],
  'overrides' => {
    'missingok' => true,
  },
}
```

The following defaults are provided:

Linux:

* daily
* rotate 14
* maxage 14
* compress
* compresscmd /usr/bin/pigz (except on CentOS 6, where pigz is not available)
* copytruncate
* notifempty
* missingok

MAC OS (BSD):

* rotate 14
* mode 644
* size 102400
* when *
* flags J

Of these compresscmd, rotate, maxage, and nocompress defaults are specified via
`node['fb_logrotate']['globals']['...']`

These maybe overridden by recipes for a particular platform.

* compresscmd - Specifies which command to use to compress log files.
  The default is pigz, except for CentOS 6 where pigz is not available. You can
  specify this by `node['fb_logrotate']['globals']['compresscmd']`
* rotate - Log files are rotated count times before being removed or mailed
  to the address specified in a mail directive. If count is 0, old versions
  are removed rather than rotated. You can specify this by
  `node['fb_logrotate']['globals']['rotate']`
* maxage - Remove rotated logs older than $COUNT days. The age is only
  checked if the logfile is to be rotated. The files are mailed to
  the configured address if `maillast` and `mail` are configured.
  You can specify this by `node['fb_logrotate']['globals']['maxage']`
* nocompress - Disables compressing the log files on rotation. Accepts a boolean
  (see below). Useful to limit disk IO or if the filesystem uses transparent file
  compression

The following attributes are optional and not populated by default.
These can be then later specified by setting the appropriate attribute
and would get picked up by this logrotate recipe.
* size - Log files are rotated if they grow bigger than size bytes.
  If size is followed by k, the size is assumed to be in kilobytes.
  If the M is used, the size is in megabytes, and if G is used,
  the size is in gigabytes. So size 100, size 100k, size 100M
  and size 100G are all valid.
  specified by `node['fb_logrotate']['globals']['size']`
* compressext - Specifies which extension to use on compressed logfiles,
  if compression is enabled.
  specified by `node['fb_logrotate']['globals']['compressext']`
* dateext (boolean) - Append daily extension to logfiles.
  specified by `node['fb_logrotate']['globals']['dateext']`
* dateformat - Format of daily extension.
  specified by `node['fb_logrotate']['globals']['dateformat']`

Overrides accepts the following booleans:

* copytruncate
* ifempty
* nocompress
* missingok
* sharedscripts
* nomail
* noolddir
* nocopytruncate
* dateext
* nodateext
* nocreate

Simply set them to true in your override hash to enable them. The following
additional overrides are accepted and require values:

* rotation     # this is how you specify daily/weekly/monthly/yearly
* rotate       # will be set to 14 if you choose daily but don't specify this
* size
* minsize
* create
* postrotate
* prerotate
* preremove
* olddir
* su
* compressoptions
* dateformat
* owner (mac os x, BSD - only)
* pid_file (mac os x, BSD - only)
* sig_num (mac os x, BSD - only)

Please don't turn off compression unless you know what you are doing, and
please specify only the minimum of overrides.

IMPORTANT NOTE: No syntax checking is done for the logrotate configs.
You are responsible for ensuring you are entering correct, typo-free
data. Please make sure that you use a valid options from logrotate(8)
otherwise warning message will be issued.

Let's go ahead and now take a look at a full sample structure, and
the resulting config file it would generate:

```
node.default['fb_logrotate']['configs']['mcproxy'] = {
  'files' => [
    "/var/log/mcproxy-tao.log",
    "/var/log/mcproxy-tao2.log",
    "/var/log/mcproxy.init.log",
    "/var/log/mcproxy.tao.log",
    "/var/log/mcproxy.tao2.log",
    "/var/log/mcproxy2.tao.log",
    "/var/log/mcproxy.log.global",
    "/var/log/mcproxy.log",
    "/var/log/mcproxy.global",
    "/var/log/mcproxy.regional.log",
  ],
  'overrides' => {
    'size' => '50M',
    'copytruncate' => true,
    'missingok' => true,
    'sharedscripts' => true,
  },
}
```

From the above structure, the following config file is generated:

```
/var/log/mcproxy-tao.log /var/log/mcproxy-tao2.log /var/log/mcproxy.init.log /var/log/mcproxy.tao.log /var/log/mcproxy.tao2.log /var/log/mcproxy2.tao.log /var/log/mcproxy.log.global /var/log/mcproxy.log /var/log/mcproxy.global /var/log/mcproxy.regional.log {
  size 50M
  copytruncate
  missingok
  sharedscripts
}
```

Another example that shows the newsyslog.d conf file as generated on a MAC
machine using the following sample strucutre:

```
node.default['fb_logrotate']['configs']['mylogfile'] = {
  'files' => ['/var/log/mylogfile'],
  'overrides' => {
    'size' => '1048576', # 1GB
  },
}
```

From the above structure, the a config file
(/etc/newsyslog.d/fb_bsd_newsyslog.conf) is generated with output:

```
# logfilename                       [owner:group]        mode count size     when  flags [/pid_file] [sig_num]
/var/log/messages                                        644  5     1024     24    J
/var/log/mylogfile                                       644  14    1048576  *     J
/var/log/secure                                          644  14    1048576  *     J
```

Note that by default rotations for /var/log/messages and /var/log/secure
are auto-populated into the newsyslog.d conf file.

### add_locking_to_logrotate
The `node['fb_logrotate']['add_locking_to_logrotate']` feature will *overwrite*
the cronjob for logrotate (/etc/cron.daily/logrotate) with one that wraps the
call to logrotate in a `flock` call to prevent logrotate runs from stepping on
each other. It also adds low priority `nice` and `ionice` to the
`logrotate` process. This can be very useful, but be aware you are
overwriting a file from the system package.

### debug_log
The `node['fb_logrotate']['debug_log']` feature is disabled by default. Setting
this to true will cause verbose logrotate output to be captured in
`/tmp/logrotate.debug.log`. This option is only available if
the `add_locking_to_logrotate` feature is also enabled.

### systemd_timer
The `node['fb_logrotate']['systemd_timer']` feature is enabled by default except
of CentOS6 and MAC OS X. It will remove the cronjob for logrotate
(/etc/cron.daily/logrotate) and setup systemd service and timer units. It also
adds low priority `nice` and `ionice` to the `logrotate` process. This can be
very useful, but be aware you are removing a file from the system package.

### timer_settings
The node['fb_logrotate']['timer_settings'] contains configuration for the
systemd timer and service units. It accepts the following:
* OnCalendar - when and how often the logrotate should run. Default 'daily'
* RandomizedDelaySec - Delay the timer by a randomly selected, evenly
                       distributed amount of time between 0 and the specified
                       time value. Default 0.
* Nice - Nice level for the logrotate process. Default 19 (lowest priority).
* IOSchedulingClass - I/O scheduling class for executed processes. Default 3 (idle).

### size and logrotate run frequency
Note that the use of the size property together with logrotate runs that are
more frequent than daily will result in `duplicate log entry` errors in
logrotate because the default dateformat is `-%Y%m%d`.  To handle this, specify
a more granular dateformat, e.g. `-%Y%m%d%H`.
