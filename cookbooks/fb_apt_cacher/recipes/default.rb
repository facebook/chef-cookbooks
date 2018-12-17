#
# Cookbook Name:: fb_apt_cacher
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.debian?
  fail 'fb_apt_cacher is only supported on Debian.'
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
