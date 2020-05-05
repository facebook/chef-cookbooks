#
# Cookbook Name:: fb_systemd
# Recipe:: udevd
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

udevadm = value_for_platform(
  'centos' => {
    '< 6.0' => '/sbin/udevadm',
  },
  'default' => '/bin/udevadm',
)

execute 'trigger udev' do
  command "#{udevadm} trigger"
  action :nothing
end

execute 'reload udev' do
  command "#{udevadm} control --reload"
  action :nothing
  notifies :run, 'execute[trigger udev]', :immediately
end

execute 'update hwdb' do
  command "#{udevadm} hwdb --update"
  action :nothing
end

directory '/etc/udev/hwdb.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/udev/hwdb.d/00-chef.hwdb' do
  source 'hwdb.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[update hwdb]', :immediately
end

template '/etc/udev/udev.conf' do
  source 'udev.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[reload udev]', :immediately
end

file '/etc/udev/rules.d/00-chef.rules' do
  action :delete
end

template '/etc/udev/rules.d/99-chef.rules' do
  source 'rules.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[reload udev]', :immediately
end

service 'systemd-udevd' do
  action [:enable, :start]
end
