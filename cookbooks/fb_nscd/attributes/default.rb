# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

# it makes sense for passwd and group to be the same settings, at least
# for most cases.
user_defaults = {
  'enable-cache' => false,
  'positive-time-to-live' => 600,
  'negative-time-to-live' => 20,
  'suggested-size' => 211,
  'check-files' => true,
  'persistent' => true,
  'shared' => true,
  'max-db-size' => 134217728,
}

hosts_defaults = {
  'enable-cache' => false,
  'positive-time-to-live' => 300,
  'negative-time-to-live' => 0,
  'suggested-size' => 211,
  'check-files' => true,
  'persistent' => true,
  'shared' => true,
  'max-db-size' => 33554432,
}

default['fb_nscd'] = {
  'configs' => {
    'server-user' => 'nscd',
    'debug-level' => 0,
    'paranoia' => false,
  },
  'passwd' => user_defaults,
  'group' => user_defaults,
  'hosts' => hosts_defaults,
}
