#
# Cookbook Name:: fb_ebtables
# Recipe:: default
#
# Copyright (c) 2018-present, Facebook, Inc.
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

unless node.centos? || node.fedora?
  fail 'fb_ebtables is only supported on CentOS and Fedora'
end

package 'ebtables' do
  only_if { node['fb_ebtables']['manage_packages'] }
  action :upgrade
end

service 'ebtables' do
  only_if { node['fb_ebtables']['enable'] }
  action :enable
end

service 'disable ebtables' do
  not_if { node['fb_ebtables']['enable'] }
  service_name 'ebtables'
  action :disable
end

template '/etc/sysconfig/ebtables-config' do
  source 'ebtables-config.erb'
  owner 'root'
  group 'root'
  mode '0600'
end
