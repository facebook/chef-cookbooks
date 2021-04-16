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
# Cookbook Name:: fb_choco
# Attributes:: default

default['fb_choco'] = {
  'enabled' => {
    'bootstrap' => false,
    'manage' => false,
  },
  'bootstrap' => {
    'version' => '0.10.3',
    'choco_download_url' => 'https://chocolatey.org/api/v2/Packages()?' +
      '$filter=((Id%20eq%20%27chocolatey%27)' +
      '%20and%20(not%20IsPrerelease))%20and%20IsLatestVersion',
    'use_windows_compression' => false,
  },
  'source_blocklist' => [],
  'sources' => {
    'chocolatey' => {
      'source' => 'https://chocolatey.org/api/v2/',
    },
  },
  'config' => {},
  'features' => {},
}
