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

smarter_sysctl = node.in_shard?(35)

template '/etc/sysctl.conf' do
  mode '0644'
  owner 'root'
  group 'root'
  source 'sysctl.conf.erb'
  unless smarter_sysctl
    notifies :run, 'execute[read-sysctl]', :immediately
  end
end

if smarter_sysctl
  fb_sysctl 'doit' do
    not_if { node.container? }
    action :apply
  end
else
  execute 'read-sysctl' do
    not_if { node.container? }
    command '/sbin/sysctl -p'
    action :nothing
  end

  # Safety check in case we missed a notification above
  execute 'reread-sysctl' do
    not_if { node.container? || FB::Sysctl.sysctl_in_sync?(node) }
    command '/sbin/sysctl -p'
  end
end
