#
# Cookbook Name:: fb_systemd
# Recipe:: timesyncd
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

template '/etc/systemd/timesyncd.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'timesyncd',
    :section => 'Time',
  )
  notifies :restart, 'service[systemd-timesyncd]'
end

service 'systemd-timesyncd' do
  only_if { node['fb_systemd']['timesyncd']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-timesyncd' do
  not_if { node['fb_systemd']['timesyncd']['enable'] }
  service_name 'systemd-timesyncd'
  action [:stop, :disable]
end
