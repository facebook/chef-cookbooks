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

default['fb_system_upgrade'] = {
  'allow_downgrades' => false,
  'early_upgrade_packages' => [],
  'early_remove_packages' => [],
  'exclude_packages' => [],
  'repos' => [],
  'wrapper' => 'nice -n 10 ionice -c 2 -n 7',
  'log' => '/var/chef/outputs/system_upgrade.log',
  # Default to a very very long timeout. We really don't want OS updates
  # being killed in the middle.
  'timeout' => 1800,
  'success_callback_method' => nil,
  'failure_callback_method' => nil,
  'notify_resources' => [],
}
