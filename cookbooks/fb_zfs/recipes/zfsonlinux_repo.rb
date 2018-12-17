#
# Cookbook Name:: fb_zfs
# Recipe:: zfsonlinux_repo
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.x64?
  fail 'fb_zfs is only supported on x86_64 hosts.'
end

distro = node['lsb']['codename']
unless ['wheezy', 'jessie'].include?(distro)
  fail 'fb_zfs is only supported on Debian Wheezy and Debian Jessie'
end

node.default['fb_apt']['repos'] <<
  "deb [arch=amd64] http://archive.zfsonlinux.org/debian #{distro} main"
node.default['fb_apt']['keys']['4D5843EA'] = nil
