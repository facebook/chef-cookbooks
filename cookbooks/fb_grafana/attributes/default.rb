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

default['fb_grafana'] = {
  'config' => {
    'paths' => {
      'data' => '/var/lib/grafana',
      'logs' => '/var/log/grafana',
      'plugins' => '/var/lib/grafana/plugins',
    },
    'server' => {
      'protocol' => 'https',
      'http_port' => 3000,
    },
  },
  'gen_selfsigned_cert' => false,
  'plugins' => {},
  'immutable_plugins' => {
    'grafana-exploretraces-app' => nil,
    'grafana-lokiexplore-app' => nil,
    'grafana-metricsdrilldown-app' => nil,
    'grafana-pyroscope-app' => nil,
  },
  'datasources' => {},
  'version' => nil,
}
