#
# Cookbook Name:: fb_apcupsd
# Recipe:: frontend
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

package 'apcupsd-cgi' do
  action :upgrade
end

template '/etc/apcupsd/hosts.conf' do
  source 'hosts.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
