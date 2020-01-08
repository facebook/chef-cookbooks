#
# Cookbook Name:: fb_dnsmasq
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

if node.centos6?
  fail 'fb_dnsmasq is not supported on CentOS 6.'
end

package 'dnsmasq' do
  action :upgrade
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  verify 'dnsmasq --test -C %{path}'
  notifies :restart, 'service[dnsmasq]'
end

service 'dnsmasq' do
  only_if { node['fb_dnsmasq']['enable'] }
  action [:enable, :start]
  subscribes :reload, 'template[/etc/hosts]'
  subscribes :reload, 'template[/etc/ethers]'
end

service 'disable dnsmasq' do
  not_if { node['fb_dnsmasq']['enable'] }
  service_name 'dnsmasq'
  action [:stop, :disable]
end
