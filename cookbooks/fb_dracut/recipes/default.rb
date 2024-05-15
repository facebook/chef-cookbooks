#
# Cookbook Name:: fb_dracut
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

unless node.centos?
  fail 'fb_dracut is only supported on CentOS.'
end

include_recipe 'fb_dracut::packages'

template '/etc/dracut.conf.d/ZZ-chef.conf' do
  not_if { node['fb_dracut']['disable'] }
  source 'dracut.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :run, 'execute[rebuild all initramfs]'
end

file '/etc/dracut.conf' do
  not_if { node['fb_dracut']['disable'] }
  action :delete
  notifies :run, 'execute[rebuild all initramfs]'
end

execute 'rebuild all initramfs' do
  not_if { node.container? || node.quiescent? || node['fb_dracut']['disable'] }
  command 'dracut --force'
  action :nothing
  subscribes :run, 'template[/etc/sysctl.conf]'
  subscribes :run, 'package[e2fsprogs]'
  subscribes :run, 'template[/etc/e2fsck.conf]'
  subscribes :run, 'template[/etc/modprobe.d/fb_modprobe.conf]'
  subscribes :run, 'template[/etc/fstab]'
  if node.systemd?
    subscribes :run, 'package[systemd packages]'
    subscribes :run, 'template[/etc/systemd/system.conf]'
  end
end
