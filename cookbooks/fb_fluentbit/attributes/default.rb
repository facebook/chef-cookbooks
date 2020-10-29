#
# Copyright (c) 2020-present, Facebook, Inc.
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

default['fb_fluentbit'] = {
  'parsers' => {},
  'plugins' => {},
  'service_config' => {
    'Flush' => 5,
    'Daemon' => 'Off',
    'Log_Level' => 'info',
    'Parsers_File' =>  'parsers.conf',
    'Plugins_File' => 'plugins.conf',
    'HTTP_Server' =>  'Off',
    'HTTP_Listen' =>  '0.0.0.0',
    'HTTP_Port' => '2020',
  },
  'external_config_url' => nil,
}
