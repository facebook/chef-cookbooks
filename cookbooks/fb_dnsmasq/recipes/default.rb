#
# Cookbook Name:: fb_dnsmasq
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
  notifies :restart, 'service[dnsmasq]'
end

service 'dnsmasq' do
  only_if { node['fb_dnsmasq']['enable'] }
  action [:enable, :start]
  subscribes :restart, 'template[/etc/hosts]'
  subscribes :restart, 'template[/etc/ethers]'
end

service 'disable dnsmasq' do
  not_if { node['fb_dnsmasq']['enable'] }
  action [:stop, :disable]
end
