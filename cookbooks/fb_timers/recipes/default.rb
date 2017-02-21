# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_timers
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.systemd?
  fail 'fb_timers is only available for use on systemd-managed machines.'
end

# This is not necessary for prod chef, but is necessary for the unit tests
# of this cookbook, since they don't run fb_systemd in any other way.
include_recipe 'fb_systemd::default'

directory 'timer path' do
  path lazy {
    node['fb_timers']['_timer_path']
  }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file 'fb_timers readme' do
  path lazy {
    "#{node['fb_timers']['_timer_path']}/README"
  }
  content "This directory is managed by the chef cookbook fb_timers.\n" +
          'DO NOT put unit files here; they will be deleted.'
  mode '0644'
  owner 'root'
  group 'root'
end

fb_timers_setup 'fb_timers system setup'
