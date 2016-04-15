#
# Cookbook Name:: fb_sysctl
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2011-present, Facebook
#

template '/etc/sysctl.conf' do
  mode '0644'
  owner 'root'
  group 'root'
  source 'sysctl.conf.erb'
  notifies :run, 'execute[read-sysctl]', :immediately
end

execute 'read-sysctl' do
  not_if { node.container? }
  command '/sbin/sysctl -p'
  action :nothing
end

# Safety check in case we missed a notification above
execute 'reread-sysctl' do
  not_if { node.container? || FB::Sysctl.sysctl_in_sync?(node) }
  command '/sbin/sysctl -p'
end
