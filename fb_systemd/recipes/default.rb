#
# Cookbook Name:: fb_systemd
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

systemd_packages = ['systemd']

case node['platform_family']
when 'rhel', 'fedora'
  systemd_packages << 'systemd-libs'
  systemd_prefix = '/usr'
when 'debian'
  systemd_packages += %w{libsystemd0 libpam-systemd}
  systemd_prefix = ''
else
  fail 'fb_systemd is not supported on this platform.'
end

package systemd_packages do
  only_if { node['fb_systemd']['manage_systemd_packages'] }
  action :upgrade
end

fb_systemd_reload 'system instance' do
  instance 'system'
  action :nothing
end

fb_systemd_reload 'all user instances' do
  instance 'user'
  action :nothing
end

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

include_recipe 'fb_systemd::journal'

# this has to be running for user sessions to work properly
service 'systemd-logind' do
  only_if { node['fb_systemd']['logind']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-logind' do
  not_if { node['fb_systemd']['logind']['enable'] }
  action [:enable, :start]
end

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

link '/etc/systemd/system/default.target' do
  to lazy { node['fb_systemd']['default_target'] }
end
