#
# Cookbook Name:: fb_dbus
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2011-present, Facebook
#
# All rights reserved - Do Not Redistribute
#

unless node.centos?
  fail 'fb_dbus only supports CentOS hosts'
end

unless node.systemd?
  fail 'fb_dbus only supports systemd hosts'
end

whyrun_safe_ruby_block 'validate dbus implementation' do
  block do
    impl = node['fb_dbus']['implementation']
    unless %w{dbus-daemon dbus-broker}.include?(impl)
      fail 'fb_dbus: invalid dbus implementation, only dbus-daemon and ' +
           'dbus-broker are supported'
    end
  end
end

include_recipe 'fb_dbus::packages'

directory '/usr/lib/systemd/scripts' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  owner 'root'
  group 'root'
  mode '0755'
end

# Drop in override to force a daemon-reload when dbus restarts (#10321854)
cookbook_file '/usr/lib/systemd/scripts/dbus-restart-hack.sh' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  owner 'root'
  group 'root'
  mode '0755'
end

directory '/etc/systemd/system/dbus.service.d' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/etc/systemd/system/dbus.service.d/dbus.conf' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  source 'dbus.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

file '/usr/lib/systemd/scripts/dbus-restart-hack.sh' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-broker' }
  action :delete
end

directory 'remove /etc/systemd/system/dbus.service.d' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-broker' }
  path '/etc/systemd/system/dbus.service.d'
  recursive true
  action :delete
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

fb_dbus_implementation 'setup dbus implementation' do
  implementation lazy { node['fb_dbus']['implementation'] }
end
