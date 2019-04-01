#
### Cookbook Name:: fb_rsync
### Recipe:: client
###
### Copyright (c) 2019-present, Facebook, Inc.
### All rights reserved.
###
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
