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

tmpfiles = {}
{
  '/dev/log' => '/run/systemd/journal/dev-log',
  '/dev/initctl' => '/run/systemd/initctl/fifo',
}.each do |dev, target|
  if File.exist?(target)
    tmpfiles[dev] = {
      'type' => 'L+',
      'argument' => target,
    }
  end
end

esp_path = nil
%w{
  /boot/efi
  /efi
  /boot
}.each do |path|
  # we test for node.filesystem_data as the plugin can occasionally fail
  # in case of e.g. hung NFS mounts, and would cause a very early Chef failure
  # with a misleading error
  if node.filesystem_data && node.filesystem_data['by_mountpoint'] &&
      node.filesystem_data['by_mountpoint'][path] &&
      node.filesystem_data['by_mountpoint'][path]['fs_type'] == 'vfat' &&
      (File.exist?("#{path}/EFI") || File.exist?("#{path}/efi"))
    esp_path = path
    break
  end
end

loader = {
  'timeout' => 3,
}
if node['machine_id']
  loader['default'] = "#{node['machine_id']}-*"
end

# Starting from 18.04, Ubuntu uses networkd, resolved and timesyncd by default,
# so default to enabling them there to prevent breakage
if node.ubuntu? &&
   FB::Version.new(node['platform_version']) >= FB::Version.new('18.04')
  enable_networkd = true
  enable_resolved = true
  enable_nss_resolve = true
  enable_timesyncd = true
else
  enable_networkd = false
  enable_resolved = false
  enable_nss_resolve = false
  enable_timesyncd = false
end

default['fb_systemd'] = {
  'default_target' => 'multi-user.target',
  'modules' => [],
  'system' => {},
  'user' => {},
  'udevd' => {
    # no enable here as systemd-udevd cannot be disabled
    'config' => {},
    'hwdb' => {},
    'rules' => [],
  },
  'journald' => {
    # no enable here as systemd-journald cannot be disabled
    'config' => {
      'Storage' => 'auto',
    },
  },
  'journal-gatewayd' => {
    'enable' => false,
  },
  'journal-remote' => {
    'enable' => false,
    'config' => {},
  },
  'journal-upload' => {
    'enable' => false,
    'config' => {},
  },
  'logind' => {
    'enable' => true,
    'config' => {},
  },
  'networkd' => {
    'enable' => enable_networkd,
  },
  'resolved' => {
    'enable' => enable_resolved,
    'enable_nss_resolve' => enable_nss_resolve,
    'config' => {},
  },
  'timesyncd' => {
    'enable' => enable_timesyncd,
    'config' => {},
  },
  'coredump' => {},
  'tmpfiles' => tmpfiles,
  'tmpfiles_excluded_prefixes' => [],
  'preset' => {},
  'manage_systemd_packages' => true,
  'boot' => {
    'enable' => false,
    'path' => esp_path,
    'loader' => loader,
    'entries' => {},
  },
  'ignore_targets' => [],
}
