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

systemd_timer = node.systemd? && !(node.centos6? || node.macosx?)

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
