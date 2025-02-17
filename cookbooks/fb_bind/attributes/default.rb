#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
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

if rpm_based?
  dir = '/var/named'
  keydir = '/etc/named/keys'
  root_hints = '/var/named/named.ca'
  sysconfig_data = {}
else
  dir = '/var/cache/bind'
  keydir = '/etc/bind/keys'
  root_hints = '/usr/share/dns/root.hints'
  sysconfig_data = {
    'resolveconf' => false,
    'options' => '-u bind',
  }
end

default['fb_bind'] = {
  'default_zone_ttl' => 3600,
  'include_record_comments_in_zonefiles' => false,
  'manage_packages' => true,
  'empty_rfc1918_zones' => false,
  'clean_config_dir' => false,
  'sysconfig' => sysconfig_data,
  'config' => {
    'options' => {
      'directory' => dir,
      'key-directory' => keydir,
      'dnssec-validation' => 'auto',
      # conform to RFC1035 by default
      'auth-nxdomain' => false,
      'allow-update' => [
        'none',
      ],
    },
    'statistics-channels' => {
      'inet 127.0.0.1 port 8053 allow' => [
        '127.0.0.1',
      ],
    },
  },
  'zones' => {
    '.' => {
      'type' => 'hint',
      '_filename' => root_hints,
    },
    'localhost.localdomain' => {
      'type' => 'primary',
      '_records' => FB::Bind::LOCALHOST_ZONEDATA,
    },
    'localhost' => {
      'type' => 'primary',
      '_records' => FB::Bind::LOCALHOST_ZONEDATA,
    },
    '127.in-addr.arpa' => {
      'type' => 'primary',
      '_records' => FB::Bind::LOOPBACK_ZONEDATA,
    },
    # v4 allocates 127.0.0.0/8 for loopback, but v6
    # only allocates a single address, so the zone is... the whole address
    FB::Bind::V6_LOOPBACK_ZONENAME => {
      'type' => 'primary',
      '_records' => FB::Bind::LOOPBACK6_ZONEDATA,
    },
    '0.in-addr.arpa' => {
      'type' => 'primary',
      '_records' => FB::Bind::STUB_ZONEDATA,
    },
    '255.in-addr.arpa' => {
      'type' => 'primary',
      '_records' => FB::Bind::STUB_ZONEDATA,
    },
  },
}
