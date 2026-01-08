# Copyright (c) Meta Platforms, Inc. and affiliates.
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
# Cookbook Name:: fb_dnf
# Recipe:: makecache

MAKECACHE_SYSTEMD_UNIT_NAME = 'dnf-makecache.timer'.freeze

if node['fb_dnf']['disable_makecache_timer'] && node['fb_dnf']['enable_makecache_timer']
  Chef::Log.error(
    '[fb_dnf] Something has set BOTH disable + enable makecache timer - Nothing will happen!',
  )
end

# If API is set to true, stop + disable the timer
systemd_unit MAKECACHE_SYSTEMD_UNIT_NAME do
  only_if { node['fb_dnf']['disable_makecache_timer'] }
  not_if { node['fb_dnf']['enable_makecache_timer'] }
  action [:stop, :disable]
end

# If API is set to false, start + enable the timer
systemd_unit MAKECACHE_SYSTEMD_UNIT_NAME do
  only_if { node['fb_dnf']['enable_makecache_timer'] }
  not_if { node['fb_dnf']['disable_makecache_timer'] }
  action [:start, :enable]
end
