# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

default['fb_rsync'] = {
  'manage_packages' => true,
  'server' => {
    'enabled' => true,
    'start_at_boot' => true,
  },
  'secure_server' => {
    'enabled' => false,
  },
  'stunnel-rsyncd.conf' => {
    'enabled_modules' => ['stunnel-rsyncd'],
    'global' => {
      'syslog' => 'no',
      'log' => 'append',
      'output' => '/var/log/rsyncd.log',
      'debug' => 5,
      'foreground' => 'yes',
    },
    'modules' => {
      'stunnel-rsyncd' => {
        'accept' => ':::10873',
        'cert' => '/etc/stunnel/stunnel_rsyncd.cert',
        'key' => '/etc/stunnel/stunnel_rsyncd.key',
        'client' => 'no',
        'exec' => '/usr/bin/rsync',
        'execargs' => '/usr/bin/rsync --daemon --config /etc/rsyncd.conf',
      },
    },
  },
  'rsyncd.conf' => {
    'enabled_modules' => [],
    'global' => {
      'gid' => 'root',
      'log file' => '/var/log/rsyncd.log',
      'log format' => '[%h %a] (%u) %o %m::%f %l (%b)',
      'pid file' => '/var/run/rsyncd.pid',
      'timeout' => '600',
      'transfer logging' => 'yes',
      'uid' => 'root',
      'use chroot' => 'yes',
    },
    'modules' => {},
  },
  'rsync_server' => nil,
  'rsync_command' =>
    'rsync -avz --timeout=60 --delete --partial --partial-dir=.rsync-partial',
}
