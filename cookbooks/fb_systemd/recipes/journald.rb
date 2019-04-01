#
# Cookbook Name:: fb_systemd
# Recipe:: journald
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
