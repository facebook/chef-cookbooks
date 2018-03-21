#
# Cookbook Name:: fb_dracut
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

unless node.centos?
  fail 'fb_dracut is only supported on CentOS.'
end

package 'dracut' do
  action :upgrade
end

template '/etc/dracut.conf' do
  source 'dracut.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[rebuild all initramfs]'
end

execute 'rebuild all initramfs' do
  not_if { node.container? }
  command 'dracut --force'
  action :nothing
  if node.systemd?
    subscribes :run, 'package[systemd packages]'
    subscribes :run, 'template[/etc/systemd/system.conf]'
    subscribes :run, 'template[/etc/sysctl.conf]'
  end
end
