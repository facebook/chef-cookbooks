#
# Cookbook Name:: fb_systemd
# Recipe:: journal
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

template '/etc/systemd/journald.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'journald',
    :section => 'Journal',
  )
  notifies :restart, 'service[systemd-journald]', :immediately
end

service 'systemd-journald' do
  action [:enable, :start]
end

directory '/var/log/journal' do
  only_if do
    %w{none volatile}.include?(node['fb_systemd']['journald']['storage'])
  end
  recursive true
  action :delete
end
