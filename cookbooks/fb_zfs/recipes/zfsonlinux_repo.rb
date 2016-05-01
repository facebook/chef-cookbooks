#
# Cookbook Name:: fb_zfs
# Recipe:: zfsonlinux_repo
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

unless node['kernel']['machine'] == 'x86_64'
  fail 'fb_zfs is only supported on x86_64 hosts.'
end

distro = node['lsb']['codename']
unless distro == 'wheezy' || distro == 'jessie'
  fail 'fb_zfs is only supported on Debian Wheezy and Debian Jessie'
end

node.default['fb_apt']['repos'] <<
  "deb [arch=amd64] http://archive.zfsonlinux.org/debian #{distro} main"
node.default['fb_apt']['keys']['4D5843EA'] = nil
