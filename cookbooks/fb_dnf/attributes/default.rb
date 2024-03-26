# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Facebook, Inc.
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

default['fb_dnf'] = {
  'config' => {
    'main' => {
      'gpgcheck' => true,
      'installonly_limit' => 3,
      'clean_requirements_on_remove' => true,
      'best' => node.centos? ? true : false,
      'skip_if_unavailable' => node.centos? ? false : true,
    },
  },
  'enable_makecache_timer' => false,
  'disable_makecache_timer' => false,
  'manage_packages' => true,
  'modules' => {},
  'repos' => {},
}
