# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_timers
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless node.systemd?
  fail 'fb_timers is only available for use on systemd-managed machines.'
end

# This is not necessary for prod chef, but is necessary for the unit tests
# of this cookbook, since they don't run fb_systemd in any other way.
include_recipe 'fb_systemd::default'

# The default timer location
directory '/etc/systemd/timers' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# The custom timer location (if different from the default)
# We create the default in addition to the custom path so the custom path
# can be inside the default path (e.g. /etc/systemd/timers/foo_bar)
directory 'timer path' do
  path lazy {
    node['fb_timers']['_timer_path']
  }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if do
    node['fb_timers']['_timer_path'] != '/etc/systemd/timers'
  end
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
