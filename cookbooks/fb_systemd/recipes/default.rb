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
  systemd_packages += %w{
    libpam-systemd
    libsystemd0
    libudev1
  }

  unless node.container?
    systemd_packages << 'udev'
  end

  # older versions of Debian and Ubuntu are missing some extra packages
  unless ['trusty', 'jessie'].include?(node['lsb']['codename'])
    systemd_packages += %w{
      libnss-myhostname
      libnss-mymachines
      libnss-resolve
      systemd-container
      systemd-coredump
      systemd-journal-remote
    }
  end

  systemd_prefix = ''
else
  fail 'fb_systemd is not supported on this platform.'
end

package 'systemd packages' do
  package_name systemd_packages
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
