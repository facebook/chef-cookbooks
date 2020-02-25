#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

globals = {
  'rotate' => '14',
  'maxage' => '14',
}

rhel_configs = {
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

debian_configs = {
  'rsyslog-syslog' => {
    'files' => ['/var/log/syslog'],
    'overrides' => {
      'rotate' => '7',
      'missingok' => true,
      'delaycompress' => true,
      # This script handles if we're using systemd or sysvinit to HUP rsyslog
      'postrotate' => '/usr/lib/rsyslog/rsyslog-rotate',
    },
  },
  'rsyslog' => {
    'files' => [
      '/var/log/auth.log',
      '/var/log/cron.log',
      '/var/log/debug',
      '/var/log/daemon.log',
      '/var/log/kern.log',
      '/var/log/lpr.log',
      '/var/log/mail.info',
      '/var/log/mail.warn',
      '/var/log/mail.err',
      '/var/log/mail.log',
      '/var/log/messages',
      '/var/log/user.log',
    ],
    'overrides' => {
      'rotate' => '4',
      'missingok' => true,
      'delaycompress' => true,
      'sharedscripts' => true,
      # This script handles if we're using systemd or sysvinit to HUP rsyslog
      'postrotate' => '/usr/lib/rsyslog/rsyslog-rotate',
    },
  },
}

# Debian/Ubuntu have different default files to rotate than RHEL/CentOS
if node.debian? || node.ubuntu?
  configs = debian_configs
else
  configs = rhel_configs
end

unless node.centos6?
  globals['compresscmd'] = '/usr/bin/pigz'
end

systemd_timer = node.systemd? && !(node.centos6? || node.macos?)

default['fb_logrotate'] = {
  'globals' => globals,
  'configs' => configs,
  'add_locking_to_logrotate' => false,
  'debug_log' => false,
  'systemd_timer' => systemd_timer,
  'systemd_settings' => {
    'OnCalendar' => 'daily',
    'RandomizedDelaySec' => 0,
    'Nice' => 19,
    'IOSchedulingClass' => 3,
  },
}
