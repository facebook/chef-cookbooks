#
# Copyright (c) 2019-present, Vicarious, Inc.
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

default['fb_nginx'] = {
  'enable' => true,
  'enable_default_site' => true,
  'manage_packages' => true,
  'sites' => {},
  'modules' => [],
  'config' => {
    '_global' => {
      'user' => 'www-data',
      'worker_processes' => 'auto',
      'pid' => '/run/nginx.pid',
      'include' => '/etc/nginx/modules-enabled/fb_modules.conf',
    },
    'events' => {
      'worker_connections' => 768,
    },
    'http' => {
      'sendfile' => 'on',
      'tcp_nopush' => 'on',
      'keepalive_timeout' => 65,
      'types_hash_max_size' => 2048,
      'include' => '/etc/nginx/mime.types',
      'default_type' => 'application/octet-stream',
      'ssl_protocols' => [
        'TLSv1',
        'TLSv1.1',
        'TLSv1.2',
      ],
      'ssl_prefer_server_ciphers' => 'on',
      'access_log' => '/var/log/nginx/access.log',
      'error_log' => '/var/log/nginx/error.log',
      'gzip' => 'on',
    },
  },
  'sysconfig' => {},
}
