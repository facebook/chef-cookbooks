#
# Cookbook Name:: fb_zfs
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

package 'zfs packages' do
  package_name %w{spl spl-dkms zfs-dkms zfsutils}
  action :upgrade
end

import_services = []
if node.systemd?
  import_services += %w{zfs-import-cache zfs-import-scan}
else
  import_services << 'zfs-import'
end

import_services.each do |svc|
  service svc do
    only_if { node['fb_zfs']['import_on_boot'] }
    action :enable
  end

  service "disable #{svc}" do
    not_if { node['fb_zfs']['import_on_boot'] }
    action :disable
  end
end

service 'zfs-zed' do
  only_if { node['fb_zfs']['enable_zed'] }
  action [:enable, :start]
end

service 'disable zfs-zed' do
  not_if { node['fb_zfs']['enable_zed'] }
  action [:stop, :disable]
end

service 'zfs-mount' do
  only_if { node['fb_zfs']['mount_on_boot'] }
  action :enable
end

service 'disable zfs-mount' do
  not_if { node['fb_zfs']['mount_on_boot'] }
  action :disable
end

service 'zfs-share' do
  only_if { node['fb_zfs']['share_on_boot'] }
  action :enable
end

service 'disable zfs-share' do
  not_if { node['fb_zfs']['share_on_boot'] }
  action :disable
end
