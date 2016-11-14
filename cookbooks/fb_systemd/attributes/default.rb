# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
  # we test for node['filesystem2'] as the plugin can occasionally fail
  # in case of e.g. hung NFS mounts, and would cause a very early Chef failure
  # with a misleading error
  if node['filesystem2'] && node['filesystem2']['by_mountpoint'][path] &&
     node['filesystem2']['by_mountpoint'][path]['fs_type'] == 'vfat' &&
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

default['fb_systemd'] = {
  'default_target' => '/lib/systemd/system/multi-user.target',
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
    'enable' => false,
  },
  'resolved' => {
    'enable' => false,
    'config' => {},
  },
  'timesyncd' => {
    'enable' => false,
    'config' => {},
  },
  'coredump' => {},
  'tmpfiles' => tmpfiles,
  'preset' => {},
  'manage_systemd_packages' => true,
  'boot' => {
    'enable' => false,
    'path' => esp_path,
    'loader' => loader,
    'entries' => {},
  },
}
