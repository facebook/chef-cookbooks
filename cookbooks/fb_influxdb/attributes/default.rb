# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['fb_influxdb'] = {
  'manage_packages' => true,
  'config' => {
    'reporting-enabled' => false,
    'meta' => {
      'dir' => '/var/lib/influxdb/meta',
    },
    'data' => {
      'dir' => '/var/lib/influxdb/data',
      'wal-dir' => '/var/lib/influxdb/wal',
    },
    'coordinator' => {},
    'retention' => {},
    'shard-precreation' => {},
    'monitor' => {},
    'http' => {
      'bind-address' => 'localhost:8086',
    },
    'ifql' => {},
    'logging' => {},
    'subscriber' => {},
    # note a typo, some sections should be rendered as [[ ]]
    '[graphite]' => {},
    '[collectd]' => {
      'enabled' => true,
      'bind-address' => '127.0.0.1:25826',
      'database' => 'collectd',
      'typesdb' => '/usr/share/collectd',
      'security-level' => 'none',
    },
    '[opentsdb]' => {},
    '[udp]' => {},
    'continuous_queries' => {},
    'tls' => {},
  },
}
