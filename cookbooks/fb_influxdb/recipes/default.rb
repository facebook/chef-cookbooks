#
# Cookbook:: fb_influxdb
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
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

unless node.debian? || node.ubuntu?
  fail 'fb_influxdb: not supported on this platform.'
end

packages = %w{
  influxdb
  influxdb-client
}

package 'influxdb packages' do
  only_if { node['fb_influxdb']['manage_packages'] }
  package_name packages
  action :upgrade
  notifies :restart, 'service[influxdb]'
end

template '/etc/influxdb/influxdb.conf' do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[influxdb]'
end

service 'influxdb' do
  action [:enable, :start]
end
