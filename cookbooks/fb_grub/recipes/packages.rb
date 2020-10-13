#
# Cookbook Name:: fb_grub
# Recipe:: packages
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

fb_grub_packages 'manage GRUB packages' do
  only_if { node['fb_grub']['manage_packages'] }
  notifies :run, 'execute[grub-install]'
end

execute 'grub-install' do
  # https://fedoraproject.org/wiki/GRUB_2 specifically says :
  # 'grub2-install shouldn't be used on EFI systems'.  See T21894396
  not_if { node.efi? }
  command lazy {
    cmd = value_for_platform_family(
      'debian' => 'grub-install',
      'rhel' => 'grub2-install',
    )
    # device of root-mount, strip off partition
    # note that this is a hack and it doesn't support properly dm devices
    d = node.device_of_mount('/').gsub(/p?\d+$/, '')
    unless d && !d.empty? && !d.start_with?('/dev/mapper')
      d = '/dev/sda'
    end
    "/usr/sbin/#{cmd} #{d}"
  }
  action :nothing
end
