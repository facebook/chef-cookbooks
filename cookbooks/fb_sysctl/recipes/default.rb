#
# Cookbook Name:: fb_sysctl
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

template '/etc/sysctl.conf' do
  mode '0644'
  owner 'root'
  group 'root'
  source 'sysctl.conf.erb'
end

fb_sysctl 'doit' do
  not_if { node.container? }
  action :apply
end
