#
# Cookbook Name:: fb_systemd
# Recipe:: journald
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

template '/etc/systemd/journald.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'journald',
    :section => 'Journal',
  )
  # we use :immediately here because this is a critical service
  notifies :restart, 'service[systemd-journald]', :immediately
end

service 'systemd-journald' do
  action [:enable, :start]
end

directory '/var/log/journal' do
  only_if do
    %w{none volatile}.include?(node['fb_systemd']['journald']['storage'])
  end
  recursive true
  action :delete
end
