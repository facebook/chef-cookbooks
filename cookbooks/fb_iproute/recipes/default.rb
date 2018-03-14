#
# Cookbook Name:: fb_iproute
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.centos?
  fail 'fb_iproute is only supported on CentOS'
end

if node.centos6?
  package 'iproute2' do
    only_if { node['fb_iproute']['manage_packages'] }
    action :upgrade
  end
else
  package %w{iproute iproute-tc} do
    only_if { node['fb_iproute']['manage_packages'] }
    action :upgrade
  end
end
