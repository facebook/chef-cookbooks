#
# Cookbook Name:: fb_zfs
# Recipe:: default
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

package 'zfs packages' do
  package_name %w{spl spl-dkms zfs-dkms zfsutils-linux}
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
    service_name svc
    action :disable
  end
end

service 'zfs-zed' do
  only_if { node['fb_zfs']['enable_zed'] }
  action [:enable, :start]
end

service 'disable zfs-zed' do
  not_if { node['fb_zfs']['enable_zed'] }
  service_name 'zfs-zed'
  action [:stop, :disable]
end

service 'zfs-mount' do
  only_if { node['fb_zfs']['mount_on_boot'] }
  action :enable
end

service 'disable zfs-mount' do
  not_if { node['fb_zfs']['mount_on_boot'] }
  service_name 'zfs-mount'
  action :disable
end

service 'zfs-share' do
  only_if { node['fb_zfs']['share_on_boot'] }
  action :enable
end

service 'disable zfs-share' do
  not_if { node['fb_zfs']['share_on_boot'] }
  service_name 'zfs-share'
  action :disable
end
