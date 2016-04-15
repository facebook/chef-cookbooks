#
# Cookbook Name:: fb_hostconf
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

template '/etc/host.conf' do
  only_if { node.centos? }
  source 'host.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
