# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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
