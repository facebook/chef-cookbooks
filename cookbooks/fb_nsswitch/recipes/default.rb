#
# Cookbook Name:: fb_nsswitch
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

template '/etc/nsswitch.conf' do
  source 'nsswitch.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
