fb_syslog Cookbook
====================
Generates valid syslog/rsyslog.conf files.

Requirements
------------

Attributes
----------
* node['fb_syslog']['syslog-entries']
* node['fb_syslog']['rsyslog_server']
* node['fb_syslog']['rsyslog_upstream']
* node['fb_syslog']['rsyslog_port']
* node['fb_syslog']['rsyslog_early_lines']
* node['fb_syslog']['rsyslog_late_lines']
* node['fb_syslog']['rsyslog_rulesets']
* node['fb_syslog']['rsyslog_nonruleset_ports']
* node['fb_syslog']['rsyslog_escape_cchars']
* node['fb_syslog']['rsyslog_additional_sockets']
* node['fb_syslog']['rsyslog_facilities_sent_to_remote']
* node['fb_syslog']['rsyslog_omprog_binary']
* node['fb_syslog']['rsyslog_use_omprog']
* node['fb_syslog']['rsyslog_use_omprog_force']
* node['fb_syslog']['rsyslog_stats_logging']
* node['fb_syslog']['rsyslog_report_suspension']
* node['fb_syslog']['sysconfig']['vars'][$KEY][$VAL]
* node['fb_syslog']['sysconfig']['extra_lines']


Usage
-----
### syslog-compatible entries
The `node['fb_syslog']['syslog-entries']` is used to populate all lines
in a `syslog.conf`, and all syslog-style entries in `rsyslog.conf`.

Each generated rule is composed of a hash entry:

    'name' => {
      comment => 'Associated comment',
      selector => '<facility>.<priority>',
      action => '<action>'
    }

The selector and action values get dumped into the config file as-is,
so you can make use of any valid syntax you wish according to
syslog.conf(5).  Each entry you create simply needs to be added into
the `node['fb_syslog']['syslog-entries']` hash with a unique
key (the key name is not used except to have a unique key).

### Additional rsyslogd configuration
By default rsyslogd runs in client mode, but if you want to run rsyslogd to
receive logging from other clients, call `recipe[fb_syslog::server]` from your
recipe or role.

You can add rsyslog-specific lines before the `syslog-entries` (mentioned above)
such as loading modules by adding lines to the array
`node['fb_syslog']['rsyslog_early_lines']`.

Similarly if you have syslog-incompatible rules that do not fit into the ruleset
APIs below, you can add lines to the array
`node['fb_syslog']['rsyslog_late_lines']` which will be included just
after the processed `syslog-entries`.

### Using RuleSets
If you have to define RuleSets to do filtering of incoming syslog, you will
define them in `node['fb_syslog']['rsyslog_rulesets']`.  This will also
open up the required network ports for listening and bind them to the RuleSet.
Here is an example for usage, also see fb_rlog recipe for a larger example:

    node.default['fb_syslog']['rsyslog_rulesets'] = {
      'incoming_music' => {
        'proto' => 'udp',
        'port' => '514',
        'rules' => {
          'Metallica' => [
              ':programname, isequal, "RideTheLightning" /var/log/metallica.log', '& ~',
          ],
          'Tool' => [
              ':hostname, contains, "Lateralus" /var/log/lateralus.log', '& ~',
              ':hostname, contains, "Aenima" /var/log/aenima.log', '& ~',
              ':hostname, contains, "10000_Days" /var/log/10000_days.log', '& ~',
              ':hostname, contains, "Undertow" /var/log/undertow.log', '& ~',
              ':hostname, contains, "Opiate" /var/log/opiate.log', '& ~',
          ],
        },
      },
    }

The output of the above example would yield:

    $RuleSet incoming_music
    # Metallica
    :programname, isequal, "RideTheLightning" /var/log/metallica.log
    & ~

    # Tool
    :hostname, contains, "Lateralus" /var/log/lateralus.log
    & ~
    :hostname, contains, "Aenima" /var/log/aenima.log
    & ~
    :hostname, contains, "10000_Days" /var/log/10000_days.log
    & ~
    :hostname, contains, "Undertow" /var/log/undertow.log
    & ~
    :hostname, contains, "Opiate" /var/log/opiate.log
    & ~

    $InputUDPServerBindRuleset incoming_music
    $UDPServerRun 514

### Opening network ports for listening
If you want to open network ports without binding them to a specific ruleset
you define these in `node['fb_syslog']['rsyslog_nonruleset_ports']`.
The most common use for this will be if you need to open ports to pass health
checks that are not already opened from your ruleset.
Here is an example:

    node.default['fb_syslog']['rsyslog_nonruleset_ports'] = {
      'tcp' => [
        '514',
        '5140',
      ],
      'udp' => [
        '514',
      ],
    }

The output of the above example would yield:

    $InputTCPServerRun 514
    $InputTCPServerRun 5140
    $InputUDPServerRun 514

These don't take effect unless `rsyslog_server` is set.

### Escaping control characters in messages
If messages entering the syslog system contain control characters and it's
causing you problems, you can enable escaping of non-printable characters by
enabling the `node['fb_syslog']['rsyslog_escape_cchars']` attribute:

    node.default['fb_syslog']['rsyslog_escape_cchars'] = true

### Enabling additional sockets
If you need to have /dev/log inside chroots, you'll need to have rsyslog
listening to additional sockets in a directory that can be bind mounted inside
the chroot. Rsyslog will create any missing directory for you.

    node.default['fb_syslog']['rsyslog_additional_sockets'] << '/dev/rsyslog/log'

The output of the above example would yield:

    $InputUnixListenSocketCreatePath on
    $AddUnixListenSocket /dev/rsyslog/log

With that, you can bind mount /dev/rsyslog to your chroot and symlink
/dev/rsyslog/log to /dev/log there.

### Remote forwarding
If you set `node['fb_syslog']['rsyslog_upstream']`, then any facilities you add
to `node['fb_syslog']['rsyslog_facilities_sent_to_remote']` will be sent to that
upstream. For example:

    node.default['fb_syslog']['rsyslog_facilities_sent_to_remote'] << 'auth.*'
    node.default['fb_syslog']['rsyslog_upstream'] << 'syslog.mydomain.com'

### Program forwarding
If you set `node['fb_syslog']['rsyslog_use_omprog']` to true, rsyslog will
use program forwarding (omprog) instead of remote forwarding (omfwd).
You will need to specify the binary to forward syslog messages to in
`node['fb_syslog']['rsyslog_omprog_binary']`. Logs from the facilities you set
in `node['fb_syslog']['rsyslog_facilities_sent_to_remote']` will be forwarded to
that binary. For example:

    node.default['fb_syslog']['rsyslog_facilities_sent_to_remote'] << 'auth.*'
    node.default['fb_syslog']['rsyslog_use_omprog'] = true
    node.default['fb_syslog']['rsyslog_omprog_binary'] = '/usr/bin/myprogram'

By default, program forwarding (omprog) will only be enabled if
`node['fb_syslog']['rsyslog_server']` is not set to `true`. You can set
`node['fb_syslog']['rsyslog_use_omprog_force']` to enable program forwarding
and a rsyslog server simultaneously. For example:

    node.default['fb_syslog']['rsyslog_use_omprog_force'] = true

### Suspension reporting
Setting `node['fb_syslog']['rsyslog_report_suspension']` controls suspension 
reporting, which defaults to `off`. If the attriubte is set to `nil` suspension
reporting will not be managed (useful e.g. if your version of rsyslog does not
support it).

### Statistics logging
Set `node['fb_syslog']['rsyslog_stats_logging']` to true to enable periodic
output of rsyslog internal counters. These will be logged using the `impstats`
module to `/var/log/rsyslog-stats.log`.

### sysconfig settings
On non-systemd systems, `node['fb_syslog']['sysconfig']` can be used
to setup `/etc/sysconfig/rsyslog` (for RedHat machines) or 
`/etc/default/rsyslog` (for Debian or Ubuntu). In general you should use it 
like this:

    node.default['fb_syslog']['sysconfig']['vars']['SYSLOGD_OPTIONS'] =
      '-c'

But the `extra_lines` array is also available for forcing arbitrary stuff like
`ulimit` calls.

