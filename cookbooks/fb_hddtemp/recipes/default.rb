#
# Cookbook Name:: fb_hddtemp
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

unless node.debian? || node.ubuntu? || node.centos?
  fail 'fb_hddtemp only supports Debian, Ubuntu and CentOS.'
end

package 'hddtemp' do
  action :upgrade
end

if node.centos?
  sysconfig = '/etc/sysconfig'
else
  sysconfig = '/etc/default'
end

template "#{sysconfig}/hddtemp" do
  source 'hddtemp.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[hddtemp]'
end

service 'hddtemp' do
  only_if { node['fb_hddtemp']['enable'] }
  action [:enable, :start]
end

service 'disable hddtemp' do
  not_if { node['fb_hddtemp']['enable'] }
  action [:stop, :disable]
end
