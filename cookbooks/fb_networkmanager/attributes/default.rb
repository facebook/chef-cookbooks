#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
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

default['fb_networkmanager'] = {
  'enable' => false,
  'manage_packages' => true,
  'system_connections' => {},
  'config' => {
    'main' => {
      'plugins' => [
        'ifupdown',
        'keyfile',
      ],
    },
    'ifupdown' => {
      # yup... this boolean does NOT take true/false like others,
      # but instead yes/no. Since there's no programmatic way to know
      # when true/false is wanted vs yes/no, we leave it up to the user
      # to specify the right one at the right time.
      #
      # NetworkManager is the worst.
      'managed' => 'no',
    },
    'device' => {
      'wifi.scan-rand-mac-address' => false,
    },
  },
}
