#
# Cookbook Name:: fb_nscd
# Recipe:: default
#
# Copyright (c) 2012-present, Facebook, Inc.
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

include_recipe 'fb_nscd::packages'

template '/etc/nscd.conf' do
  only_if { FB::Nscd.nscd_enabled?(node) }
  owner 'root'
  group 'root'
  mode '0644'
  source 'nscd.conf.erb'
  notifies :restart, 'service[nscd]', :immediately
end

service 'nscd' do
  only_if { FB::Nscd.nscd_enabled?(node) }
  action [:enable, :start]
  subscribes :restart, 'template[/etc/ldap.conf]', :immediately
end

service 'disable nscd' do
  not_if { FB::Nscd.nscd_enabled?(node) }
  service_name 'nscd'
  action [:stop, :disable]
end

package 'remove nscd' do
  not_if { FB::Nscd.nscd_enabled?(node) }
  package_name 'nscd'
  action :remove
end
