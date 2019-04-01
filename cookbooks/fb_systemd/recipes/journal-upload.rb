#
# Cookbook Name:: fb_systemd
# Recipe:: journal-upload
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
