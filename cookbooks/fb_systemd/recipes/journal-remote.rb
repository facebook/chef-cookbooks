#
# Cookbook Name:: fb_systemd
# Recipe:: journal-remote
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

template '/etc/systemd/journal-remote.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'journal-remote',
    :section => 'Remote',
  )
  notifies :restart, 'service[systemd-journal-remote]'
end

directory '/var/log/journal/remote' do
  only_if { node['fb_systemd']['journal-remote']['enable'] }
  owner 'systemd-journal-remote'
  group 'systemd-journal-remote'
  mode '2755'
end

service 'systemd-journal-remote' do
  only_if { node['fb_systemd']['journal-remote']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-journal-remote' do
  not_if { node['fb_systemd']['journal-remote']['enable'] }
  service_name 'systemd-journal-remote'
  action [:stop, :disable]
end
