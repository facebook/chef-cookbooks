#
# Cookbook Name:: fb_securetty
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

template '/etc/securetty' do
  source 'securetty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end
