#
# Cookbook:: fb_cyrus
# Recipe:: default
#
# Copyright (c) 2025-present, Facebook, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

packages = %w{
  cyrus-admin
  cyrus-clients
  cyrus-imapd
}

package 'cyrus packages' do
  only_if { node['fb_cyrus']['manage_packages'] }
  package_name packages
  action :upgrade
end

template '/etc/cyrus.conf' do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[cyrus-imapd]'
end

template '/etc/imapd.conf' do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[cyrus-imapd]'
end

service 'cyrus-imapd' do
  action [:enable, :start]
end
