#
# Copyright (c) Meta Platforms, Inc. and affiliates.
# Copyright (c) 2021-present, Vicarious, Inc.
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

default['fb_smokeping'] = {
  'general' => {
    'owner' => 'Peter Random',
    'contact' => 'somewhere@example.com',
    'mailhost' => 'my.mail.host',
    'cgiurl' => 'http://some.url/smokeping.cgi',
    'syslogfacility' => 'local0',
  },
  'probes' => {
    'FPing' => {
      'binary' => '/usr/bin/fping',
      'step' => 60,
      'pings' => 10,
    },
    'FPing6' => {
      'binary' => '/usr/bin/fping6',
      'step' => 60,
      'pings' => 10,
    },
    'EchoPingHttp' => {
      'binary' => '/usr/bin/echoping',
      'forks' => 5,
      'offset' => '50%',
      'step' => 120,
      'pings' => 4,
    },
    'EchoPingHttps' => {
      'binary' => '/usr/bin/echoping',
      'forks' => 5,
      'offset' => '50%',
      'step' => 120,
      'pings' => 4,
    },
    'DNS' => {
      'binary' => '/usr/bin/dig',
      'forks' => 5,
      'offset' => '50%',
      'step' => 60,
      'timeout' => 15,
      'pings' => 5,
    },
  },
  'secrets' => {},
  'targets' => {
    'title' => 'Network Latency Grapher',
    'probe' => 'FPing',
    'menu' => 'Top',
  },
}
