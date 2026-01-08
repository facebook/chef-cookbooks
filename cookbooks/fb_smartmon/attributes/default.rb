# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) Meta Platforms, Inc. and affiliates.
# Copyright (c) 2022-present, Vicarious, Inc.
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

return unless node.linux?

if node['block_device'].keys.any? { |x| x.start_with?('nvme') }
  devicetype = 'nvme'
else
  devicetype = 'auto'
end

default['fb_smartmon'] = {
  'enable' => false,
  'config' => {
    'devicescan' => {
      '-d' => devicetype,
    },
  },
}
