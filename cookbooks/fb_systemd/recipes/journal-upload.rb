#
# Cookbook Name:: fb_systemd
# Recipe:: journal-upload
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

template '/etc/systemd/journal-upload.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'journal-upload',
    :section => 'Upload',
  )
  notifies :restart, 'service[systemd-journal-upload]'
end

service 'systemd-journal-upload' do
  only_if { node['fb_systemd']['journal-upload']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-journal-upload' do
  not_if { node['fb_systemd']['journal-upload']['enable'] }
  service_name 'systemd-journal-upload'
  action [:stop, :disable]
end
