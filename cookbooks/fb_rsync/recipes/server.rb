#
# Cookbook Name:: fb_rsync
# Recipe:: server
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# client package
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

systemd_unit 'rsyncd.service' do
  only_if { node.centos8? }
  # This will only start if the magical file exists
  action [:create]
  content <<-EOU.gsub(/^\s+/, '')
    [Unit]
    Description=fast remote file copy program daemon
    ConditionPathExists=/etc/rsyncd.conf

    [Service]
    # EnvironmentFile=/etc/sysconfig/rsyncd
    ExecStart=/usr/bin/rsync --daemon --no-detach "$OPTIONS"

    [Install]
    WantedBy=multi-user.target
  EOU
end

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
