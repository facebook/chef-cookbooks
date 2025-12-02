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

rundir = '/run/opendkim'

default['fb_opendkim'] = {
  'manage_packages' => true,
  'config' => {
    'Syslog' => 'yes',
    'SyslogSuccess' => 'yes',
    'Canonicalization' => 'relaxed/simple',
    'OversignHeaders' => 'From',
    'UserID' => 'opendkim',
    'UMask' => '007',
    'Socket' => "local:#{rundir}/opendkim.sock",
    'PidFile' => '/run/opendkim/opendkim.pid',
    'TrustAnchorFile' => '/usr/share/dns/root.key',
  },
  'sysconfig' => {
    'rundir' => '/run/opendkim',
    # if you specify a socket here, it'll override the config
    # since it's _required_ in the config, put it only there and
    # not here.
    'user' => 'opendkim',
    'group' => 'opendkim',
    'pidfile' => '$RUNDIR/$NAME.pid',
  },
}
