#
# Cookbook Name:: fb_systemd
# Recipe:: udevd
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

execute 'trigger udev' do
  command '/sbin/udevadm trigger'
  action :nothing
end

execute 'reload udev' do
  command '/sbin/udevadm control --reload'
  action :nothing
  notifies :run, 'execute[trigger udev]', :immediately
end

execute 'update hwdb' do
  command '/sbin/udevadm hwdb --update'
  action :nothing
end

directory '/etc/udev/hwdb.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/udev/hwdb.d/00-chef.hwdb' do
  source 'hwdb.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[update hwdb]', :immediately
end

template '/etc/udev/udev.conf' do
  source 'udev.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[reload udev]', :immediately
end

template '/etc/udev/rules.d/00-chef.rules' do
  source 'rules.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # we use :immediately here because this is a critical service
  notifies :run, 'execute[reload udev]', :immediately
end

service 'systemd-udevd' do
  action [:enable, :start]
end
