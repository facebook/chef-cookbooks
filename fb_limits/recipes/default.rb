#
# Cookbook Name:: fb_limits
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
