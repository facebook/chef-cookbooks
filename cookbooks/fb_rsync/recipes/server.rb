#
# Cookbook Name:: fb_rsync
# Recipe:: server
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

# package and stuff is in the client
include_recipe 'fb_rsync::client'

# In lieu of running rsync via xinetd we use a simple init script
cookbook_file '/etc/init.d/rsyncd' do
  not_if { node.systemd? }
  group 'root'
  mode '0755'
  owner 'root'
  source 'rsyncd.init'
end

# This is the default config everywhere
template '/etc/rsyncd.conf' do
  group 'root'
  mode '0644'
  notifies :restart, 'service[rsyncd start]'
  owner 'root'
  source 'rsyncd.conf.erb'
end

node.default['fb_logrotate']['configs']['rsyncd'] = {
  'files' => ['/var/log/rsyncd.log'],
  'overrides' => {
    'delaycompress' => true,
  },
}

svc = value_for_platform_family(
  'rhel' => 'rsyncd',
  'debian' => 'rsync',
  'default' => 'rsyncd',
)

# This resource order is more pleasing in the logs
service 'rsyncd enable' do
  service_name svc
  only_if { node['fb_rsync']['server']['start_at_boot'] }
  action [:enable]
  supports :status => true
end

service 'rsyncd start' do
  service_name svc
  only_if { node['fb_rsync']['server']['enabled'] }
  action [:start]
  supports :restart => true, :status => true
end

service 'rsyncd disable' do
  service_name svc
  not_if { node['fb_rsync']['server']['start_at_boot'] }
  action [:disable]
  supports :status => true
end

service 'rsyncd stop' do
  service_name svc
  not_if { node['fb_rsync']['server']['enabled'] }
  action [:stop]
  supports :status => true
end
