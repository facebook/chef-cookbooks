#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

property :kea_group, String, :required => true
action :create do
  path = ::File.join(
    node['fb_kea']['config']['control-agent']['authentication']['directory'],
    node['fb_kea']['config']['control-agent']['authentication'][
      'clients-hash']['default']['password-file'],
  )

  # despite 'lazy', the block will run, even if :create_if_missing
  # decides it doesn't need to install the file. It's silly to waste
  # the random (or the CPU), so we make this into a custom resource
  # we can return from if the file exists.
  return if ::File.exist?(path)

  file path do
    owner node.root_user
    group new_resource.kea_group
    mode '0640'
    content lazy {
      SecureRandom.alphanumeric(25)
    }
    action :create_if_missing
  end
end
