#
# Cookbook Name:: fb_systemd
# Recipe:: logind
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
  # We need to suppress restarts of the logind service on client machines, as
  # a restart will cause the user to loose keyboard and mouse control of the
  # graphical interface.
  not_if { node['fb_systemd']['default_target'].include?('graphical.target') }
  action [:enable, :start]
end

service 'disable systemd-logind' do
  service_name 'systemd-logind'
  not_if { node['fb_systemd']['logind']['enable'] }
  action [:stop, :disable]
end
