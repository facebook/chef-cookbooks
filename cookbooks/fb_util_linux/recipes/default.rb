# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_util_linux
# Recipe:: default
#
# Copyright (c) 2018-present, Facebook, Inc.
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

# TODO: use fedora_derived?
unless node.centos? || node.rhel? || node.fedora?
  fail 'fb_util_linux: this cookbook is only supported on Fedora-based distros.'
end

include_recipe 'fb_util_linux::packages'

node.default['fb_systemd']['preset']['fstrim.timer'] = 'disable'

service 'fstrim.timer' do
  only_if { node['fb_util_linux']['enable_fstrim'] }
  action [:enable, :start]
end

service 'disable fstrim.timer' do
  not_if { node['fb_util_linux']['enable_fstrim'] }
  service_name 'fstrim.timer'
  action [:stop, :disable]
end
