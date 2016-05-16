#
# Cookbook Name:: fb_hddtemp
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
  owner 'root'
  group 'root'
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
