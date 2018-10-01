# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_iptables
# Recipe:: packages
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

packages = ['iptables']
if node.centos6?
  packages << 'iptables-ipv6'
elsif node.ubuntu?
  packages << 'iptables-persistent'
else
  packages << 'iptables-services'
end

package packages do
  only_if { node['fb_iptables']['manage_packages'] }
  action :upgrade
  notifies :run, 'execute[reload iptables]'
  notifies :run, 'execute[reload ip6tables]'
end
