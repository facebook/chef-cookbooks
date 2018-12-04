#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

globals = {
  'rotate' => '14',
  'maxage' => '14',
}

configs = {
  'syslog' => {
    'files' => [
      '/var/log/cron',
      '/var/log/maillog',
      '/var/log/messages',
      '/var/log/secure',
      '/var/log/spooler',
    ],
    'overrides' => {
      'nocreate' => true,
      'nocopytruncate' => true,
      'missingok' => true,
      'sharedscripts' => true,
      'postrotate' => (node.systemd? ?
         '/bin/systemctl kill -s HUP rsyslog || true' :
         '(/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> ' +
         '/dev/null || true) && ' +
         '(/bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> ' +
         '/dev/null || true)'),
    },
  },
}

unless node.centos6?
  globals['compresscmd'] = '/usr/bin/pigz'
end

default['fb_logrotate'] = {
  'globals' => globals,
  'configs' => configs,
  'add_locking_to_logrotate' => false,
  'debug_log' => false,
}
