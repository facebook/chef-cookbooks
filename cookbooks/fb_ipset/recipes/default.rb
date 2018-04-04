#
# Cookbook Name:: fb_ipset
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
  fail 'fb_ipset is only supported on CentOS hosts'
end

pkgs = ['ipset']
unless node.centos6?
  pkgs << 'ipset-service'
end

package pkgs do
  only_if { node['fb_ipset']['manage_packages'] }
  action :upgrade
end

if node.centos6?
  cookbook_file '/etc/init.d/ipset' do
    only_if { node['fb_ipset']['enable'] }
    source 'ipset-init'
    owner 'root'
    group 'root'
    mode '0755'
  end

  service 'ipset' do
    only_if { node['fb_ipset']['enable'] }
    action :enable
  end

  service 'ipset disable' do
    service_name 'ipset'
    not_if { node['fb_ipset']['enable'] }
    action :disable
  end
end

fb_ipset 'fb_ipset' do
  action :update

  # backwards compatibility. some cookbooks use the fb_ipset cookbook for
  # installing the ipset package, and probably manage the sets on their own.
  # this makes sure this cookbook won't delete all their ipsets if they don't
  # switch to the node['fb_ipset']['sets'] API
  only_if { node['fb_ipset']['enable'] }
end

fb_ipset 'fb_ipset_auto_cleanup_if_enabled' do
  action :cleanup
  only_if { node['fb_ipset']['enable'] && node['fb_ipset']['auto_cleanup'] }
end
