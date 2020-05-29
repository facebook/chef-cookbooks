#
# Cookbook Name:: fb_ipset
# Recipe:: default
#
# Copyright (c) 2017-present, Facebook, Inc.
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

unless node.linux?
  fail 'fb_ipset is only supported on Linux'
end

include_recipe 'fb_ipset::default_packages'

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

directory '/etc/ipset' do
  owner 'root'
  group 'root'
  mode '0755'
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
