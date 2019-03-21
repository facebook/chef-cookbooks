#
### Cookbook Name:: fb_rsync
### Recipe:: client
###
### Copyright (c) 2019-present, Facebook, Inc.
### All rights reserved.
###
### This source code is licensed under the BSD-style license found in the
### LICENSE file in the root directory of this source tree. An additional grant
### of patent rights can be found in the PATENTS file in the same directory.
###
##
#
include_recipe 'fb_systemd::reload'
include_recipe 'fb_rsync::secure_client'
include_recipe 'fb_rsync::server'

fail 'fb_rsync::secure_server supports only systemd nodes' unless node.systemd?

cookbook_file '/etc/systemd/system/stunnel_rsyncd.service' do
  group 'root'
  mode '0644'
  owner 'root'
  source 'stunnel_rsyncd.service'
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

template '/etc/stunnel/stunnel_rsyncd.conf' do
  group 'root'
  mode '0644'
  notifies :restart, 'service[stunnel_rsyncd start]'
  owner 'root'
  source 'stunnel_rsyncd.conf.erb'
end

svc = 'stunnel_rsyncd.service'

service 'stunnel_rsyncd start' do
  only_if { node['fb_rsync']['secure_server']['enabled'] }
  service_name svc
  action [:enable, :start]
end

service 'stunnel_rsyncd stop' do
  not_if { node['fb_rsync']['secure_server']['enabled'] }
  service_name svc
  action [:stop, :disable]
end
