# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_apcupsd'] = {
  'enable' => true,
  'config' => {
    # General options
    'upsname' => node['hostname'],
    'upscable' => 'usb',
    'upstype' => 'usb',
    'device' => '',
    'lockfile' => '/var/lock',
    'scriptdir' => '/etc/apcupsd',
    'pwrfaildir' => '/etc/apcupsd',
    'nologindir' => '/etc',
    # Power failure options
    'onbatterydelay' => 6,
    'batterylevel' => 5,
    'minutes' => 3,
    'timeout' => 0,
    'annoy' => 300,
    'annoydelay' => 60,
    'nologon' => 'disable',
    'killdelay' => 0,
    # Network Information Server
    'netserver' => 'on',
    'nisip' => '127.0.0.1',
    'nisport' => 3551,
    'eventsfile' => '/var/log/apcupsd.events',
    'eventsfilemax' => 10,
    # APC ShareUPS settings
    'upsclass' => 'standalone',
    'upsmode' => 'disable',
    # Logging
    'stattime' => 0,
    'statfile' => '/var/log/apcupsd.status',
    'logstats' => 'off',
    'datatime' => 0,
  },
  'hosts' => {
    '127.0.0.1' => node['hostname'],
  },
}
