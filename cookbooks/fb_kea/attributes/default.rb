#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2025-present, Phil Dibowitz
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

basic_logger_hash = {
  'stdout' => {
    'name' => 'stdout',
    'output-options' => [
      {
        'output' => 'stdout',
      },
    ],
    'severity' => 'INFO',
    'debuglevel' => 0,
  },
}
sock4 = '/run/kea/kea4-ctrl-socket'
sock6 = '/run/kea/kea6-ctrl-socket'
sockd = '/run/kea/kea-ddns-ctrl-socket'

default['fb_kea'] = {
  'manage_packages' => true,
  'enable_dhcp4' => true,
  'eanble_dhcp6' => true,
  'enable_ddns' => false,
  'enable_control-agent' => true,
  'verify_aa_workaround' => false,
  'config' => {
    '_common' => {
      'interfaces-config' => {
        'interfaces' => [
          node['network']['default_interface'],
        ],
      },
      'lease-database' => {
        'type' => 'memfile',
        'lfc-interval' => 3600,
      },
      'control-socket' => {
        'socket-type' => 'unix',
      },
      'dhcp-ddns' => {
        'enable-updates' => false,
      },
      'reservations-global' => false,
      'reservations-in-subnet' => true,
      'reservations-out-of-pool' => true,
      'host-reservation-identifiers' => [
        'hw-address',
      ],
      'loggers-hash' => basic_logger_hash,
      'client-classes-hash' => {},
      'option-data-hash' => {},
    },
    'dhcp4' => {
      'interfaces-config' => {
        'dhcp-socket-type' => 'raw',
      },
      'control-socket' => {
        'socket-name' => sock4,
      },
      'authoritative' => true,
      'subnet4-hash' => {},
    },
    'dhcp6' => {
      'control-socket' => {
        'socket-name' => sock6,
      },
      'subnet6-hash' => {},
    },
    'ddns' => {
      :'ip-address' => '127.0.0.1',
      :port => 43001,
      'loggers-hash' => basic_logger_hash,
      'control-socket' => {
        'socket-type' => 'unix',
        'socket-name' => sockd,
      },
      'forward-ddns' => {},
      'reverse-ddns' => {},
    },
    'control-agent' => {
      'http-host' => '127.0.0.1',
      'http-port' => 8000,
      'authentication' => {
        'type' => 'basic',
        'realm' => 'Kea Control Agent',
        'directory' => '/etc/kea',
        'clients-hash' => {
          'default' => {
            'user' => 'kea-api',
            'password-file' => 'kea-api-password',
          },
        },
      },
      'loggers-hash' => basic_logger_hash,
    },
  },
}
