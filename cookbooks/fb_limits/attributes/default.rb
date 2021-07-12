# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

if node.in_shard?(39)
  memlock_limit = node['memory']['total'].to_i / 1024
  default['fb_limits']['*'] = {
    'memlock' => {
      'soft' => memlock_limit,
      'hard' => memlock_limit,
    },
  }
end

default['fb_limits']['root'] = {
  'nofile' => {
    'hard' => '65535',
    'soft' => '65535',
  },
}

# Only set limit on centos6 as centos5 has a very high default limit already.
# CentOS 6 defaults to 1024
if node.centos6?
  default['fb_limits']['*'] = {
    'nproc' => {
      'hard' => '61278',
      'soft' => '61278',
    },
  }
end
