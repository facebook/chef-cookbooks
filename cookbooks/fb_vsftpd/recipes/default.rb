#
# Cookbook Name:: fb_vsftpd
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
