#
# Cookbook Name:: fb_p910nd
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.debian? || node.ubuntu?
  fail 'fb_p910nd is only supported on Debian and Ubuntu.'
end

package 'p910nd' do
  action :upgrade
end

template '/etc/default/p910nd' do
  source 'p910nd.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[p910nd]'
end

service 'p910nd' do
  action [:enable, :start]
end
