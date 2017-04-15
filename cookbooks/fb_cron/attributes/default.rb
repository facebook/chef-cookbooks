# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
default['fb_cron'] = {
  'jobs' => {},
  'environment' => {},
  'anacrontab' => {
    'environment' => {
      'shell' => '/bin/sh',
      'path' => '/sbin:/bin:/usr/sbin:/usr/bin',
      'mailto' => 'root',
      'random_delay' => '45',
      'start_hours_range' => '3-22',
    },
  },

  # Path for the crontab that contains all the fb_cron job entries.
  # This is a hidden attribute because people shouldn't change this unless
  # they know what they're doing.
  '_crontab_path' => '/etc/cron.d/fb_crontab',
}
