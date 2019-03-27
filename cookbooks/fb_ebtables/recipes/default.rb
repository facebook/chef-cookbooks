#
# Cookbook Name:: fb_ebtables
# Recipe:: default
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.centos? || node.fedora?
  fail 'fb_ebtables is only supported on CentOS and Fedora'
end

package 'ebtables' do
  only_if { node['fb_iptables']['manage_packages'] }
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
