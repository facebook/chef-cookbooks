#
# Cookbook Name:: fb_systemd
# Recipe:: logind
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

template '/etc/systemd/logind.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'logind',
    :section => 'Login',
  )
  # we use :immediately here because this is a critical service for user
  # sessions to work
  notifies :restart, 'service[systemd-logind]', :immediately
end

service 'systemd-logind' do
  only_if { node['fb_systemd']['logind']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-logind' do
  service_name 'systemd-logind'
  not_if { node['fb_systemd']['logind']['enable'] }
  action [:stop, :disable]
end
