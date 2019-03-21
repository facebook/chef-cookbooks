# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

default['fb_rsync'] = {
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
