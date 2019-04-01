#
# Cookbook Name:: fb_apcupsd
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
  fail 'fb_apcupsd is only supported on Debian, Ubuntu or CentOS.'
end

if node.centos6?
  fail 'fb_apcupsd is not supported on CentOS 6.'
end

package 'apcupsd' do
  action :upgrade
end

# this isn't a template as there's nothing really useful to configure in it
cookbook_file '/etc/default/apcupsd' do
  only_if { node.debian? || node.ubuntu? }
  source 'apcupsd'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apcupsd]'
end

template '/etc/apcupsd/apcupsd.conf' do
  source 'apcupsd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apcupsd]'
end

service 'apcupsd' do
  only_if { node['fb_apcupsd']['enable'] }
  action [:enable, :start]
end

service 'disable apcupsd' do
  not_if { node['fb_apcupsd']['enable'] }
  action [:stop, :disable]
end
