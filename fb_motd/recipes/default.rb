#
# Cookbook Name:: fb_motd
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

template '/etc/motd' do
  not_if { node['motd_exempt'] }
  group 'root'
  mode '0644'
  owner 'root'
  source 'motd.erb'
end
