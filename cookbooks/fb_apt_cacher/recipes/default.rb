#
# Cookbook Name:: fb_apt_cacher
# Recipe:: default
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

unless node.debian? || node.ubuntu?
  fail 'fb_apt_cacher is only supported on Debian-like Distros.'
end

package 'apt-cacher-ng' do
  action :upgrade
end

%w{CacheDir LogDir}.each do |dir|
  directory dir do
    path lazy { node['fb_apt_cacher']['config'][dir] }
    owner 'apt-cacher-ng'
    group 'apt-cacher-ng'
    mode '2755'
  end
end

template '/etc/default/apt-cacher-ng' do
  source 'apt-cacher-ng.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apt-cacher-ng]'
end

template '/etc/apt-cacher-ng/acng.conf' do
  source 'acng.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :section => 'config',
  )
  notifies :restart, 'service[apt-cacher-ng]'
end

template '/etc/apt-cacher-ng/security.conf' do
  source 'acng.conf.erb'
  owner 'apt-cacher-ng'
  group 'apt-cacher-ng'
  mode '0600'
  variables(
    :section => 'security',
  )
  notifies :restart, 'service[apt-cacher-ng]'
end

service 'apt-cacher-ng' do
  action [:enable, :start]
end
