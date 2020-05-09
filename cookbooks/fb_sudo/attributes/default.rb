#
# Copyright (c) 2019-present, Vicarious, Inc.
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

default['fb_sudo'] = {
  'manage_packages' => true,
  'aliases' => {
    'host' => {},
    'user' => {},
    'command' => {},
    'runas' => {},
  },
  'defaults' => {
    'visiblepw' => false,
    'always_set_home' => true,
    'env_reset' => true,
    'env_keep' => 'COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS ' +
      'MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE ' +
      'LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES ' +
      'LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE ' +
      'LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY',
    'secure_path' => '/sbin:/bin:/usr/sbin:/usr/bin',
  },
  'default_overrides' => {},
  'users' => value_for_platform_family(
    :default => {
      '%sudo' => {
        'all' => 'ALL=(ALL) ALL',
      },
      # uncomment the block below when debugging kitchen tests
      # 'kitchen' => {
      #   'all' => 'ALL=(ALL) NOPASSWD: ALL',
      # },
    },
    'mac_os_x' => {
      'root' => {
        'all' => 'ALL=(ALL) ALL',
      },
      '%admin' => {
        'all' => 'ALL=(ALL) ALL',
      },
    },
  ),
}
