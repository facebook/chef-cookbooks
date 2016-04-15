#
# Cookbook Name:: fb_limits
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

template '/etc/security/limits.conf' do
  source 'limits.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# We want to manage all limits config via /etc/security/limits.conf so
# clean out limits.d
directory '/etc/security/limits.d' do
  only_if { Dir.exists?('/etc/security/limits.d') }
  action :delete
  recursive true
end
