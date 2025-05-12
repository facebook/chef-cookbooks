#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook:: fb_openport
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

fb_openport_package 'doit' do
  only_if { node['fb_openport']['manage_packages'] }
  notifies :restart, 'fb_openport_services[all]'
end

# This unit file has been contributed to openport:
# https://github.com/openportio/openport-go/pull/4
#
# But is not yet in any released packages.  So we check for a packaged one and
# if it's not there, we install one in /etc
cookbook_file '/etc/systemd/system/openport@.service' do
  not_if { ::File.exist?('/lib/systemd/system/openport@.service') }
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

# conversely, if one is there, we delete the one we installed
file '/etc/systemd/system/openport@.service' do
  only_if { ::File.exist?('/lib/systemd/system/openport@.service') }
  action :delete
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

# Further, stop and mask the generated service from the init script.
#
# The stopping is important as we don't want to be running the built-in
# openport supervisor, we only want systemd-supervised sesions.
#
# Disabling won't work as expected since it's not a real unit, so we want
# to maxk it so that systemd won't generate a fresh enabled unit on reboot.
service 'openport' do
  action [:stop, :mask]
end

sysconfig_path = if ChefUtils.fedora_derived?
                   '/etc/sysconfig'
                 else
                   '/etc/default'
                 end

template ::File.join(sysconfig_path, 'openport') do
  owner node.root_user
  group node.root_group
  mode '0644'
  source 'sysconfig.erb'
  variables({ 'instance' => 'global' })
  notifies :restart, 'fb_openport_services[all]'
end

fb_openport_services 'all' do
  action :setup
end
