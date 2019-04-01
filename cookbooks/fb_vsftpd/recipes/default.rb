#
# Cookbook Name:: fb_vsftpd
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

unless node.centos? || node.debian? || node.ubuntu?
  fail 'fb_vsftpd is only supported on CentOS, Debian or Ubuntu'
end

package 'vsftpd' do
  action :upgrade
  notifies :restart, 'service[vsftpd]'
end

prefix = value_for_platform_family(
  'rhel' => '/etc/vsftpd',
  'debian' => '/etc',
)

user_list = value_for_platform_family(
  'rhel' => "#{prefix}/user_list",
  'debian' => "#{prefix}/vsftpd.user_list",
)

template "#{prefix}/vsftpd.conf" do
  source 'vsftpd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[vsftpd]'
end

template "#{prefix}/ftpusers" do
  source 'ftpusers.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[vsftpd]'
  variables(
    :section => 'ftpusers',
  )
end

template user_list do
  source 'ftpusers.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[vsftpd]'
  variables(
    :section => 'user_list',
  )
end

service 'vsftpd' do
  only_if { node['fb_vsftpd']['enable'] }
  action [:enable, :start]
end

service 'disable vsftpd' do
  not_if { node['fb_vsftpd']['enable'] }
  service_name 'vsftpd'
  action [:stop, :disable]
end
