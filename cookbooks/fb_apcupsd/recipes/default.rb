#
# Cookbook Name:: fb_apcupsd
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
