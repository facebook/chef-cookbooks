#
# Cookbook Name:: fb_systemd
# Recipe:: journal-remote
#
# Copyright (c) 2016-present, Facebook, Inc.
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
