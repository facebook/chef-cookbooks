#
# Cookbook Name:: fb_motd
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

template '/etc/motd' do
  group 'root'
  mode '0644'
  owner 'root'
  source 'motd.erb'
end
