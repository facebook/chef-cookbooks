#
# Cookbook Name:: fb_systemd
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.systemd?
  fail 'fb_systemd is only available on systemd-enabled hosts'
end

case node['platform_family']
when 'rhel', 'fedora'
  systemd_prefix = '/usr'
when 'debian'
  systemd_prefix = ''
else
  fail 'fb_systemd is not supported on this platform.'
end

include_recipe 'fb_systemd::default_packages'
include_recipe 'fb_systemd::reload'

template '/etc/systemd/system.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'system',
    :section => 'Manager',
  )
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

template '/etc/systemd/user.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'user',
    :section => 'Manager',
  )
  notifies :run, 'fb_systemd_reload[all user instances]', :immediately
end

template '/etc/systemd/coredump.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'coredump',
    :section => 'Coredump',
  )
end

unless node.container?
  include_recipe 'fb_systemd::udevd'
end
include_recipe 'fb_systemd::journald'
include_recipe 'fb_systemd::journal-gatewayd'
include_recipe 'fb_systemd::journal-remote'
include_recipe 'fb_systemd::journal-upload'
include_recipe 'fb_systemd::logind'
include_recipe 'fb_systemd::networkd'
include_recipe 'fb_systemd::resolved'
include_recipe 'fb_systemd::timesyncd'
include_recipe 'fb_systemd::boot'

execute 'process tmpfiles' do
  command "#{systemd_prefix}/bin/systemd-tmpfiles --create"
  action :nothing
end

template '/etc/tmpfiles.d/chef.conf' do
  source 'tmpfiles.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[process tmpfiles]'
end

execute 'load modules' do
  command "#{systemd_prefix}/lib/systemd/systemd-modules-load"
  action :nothing
end

directory '/etc/systemd/system-preset' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/systemd/system-preset/00-fb_systemd.preset' do
  source 'preset.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory '/etc/systemd/user/default.target.wants' do
  owner 'root'
  group 'root'
  mode '0755'
end

link '/etc/systemd/system/default.target' do
  to lazy { node['fb_systemd']['default_target'] }
end
