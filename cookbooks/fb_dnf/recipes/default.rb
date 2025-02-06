#
# Cookbook Name:: fb_dnf
# Recipe:: default
#
# Copyright (c) 2021-present, Facebook, Inc.
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

unless node.centos? || node.fedora?
  fail 'fb_dnf: this cookbook only supports CentOS and Fedora'
end

if node.centos? && node['platform_version'].to_i < 8
  fail 'fb_dnf: DNF is only supported from CentOS 8 onwards'
end

include_recipe 'fb_yum_repos'

directory '/etc/dnf' do
  owner node.root_user
  group node.root_group
  mode '0755'
end

fb_yum_repos_config '/etc/dnf/dnf.conf' do
  config lazy { node['fb_dnf']['config'] }
  repos lazy { node['fb_dnf']['repos'] }
  notifies :run, 'execute[clean yum metadata]', :immediately
  notifies :run, 'whyrun_safe_ruby_block[clean chef yum metadata]', :immediately
end

fb_dnf_modularity 'manage modularity' do
  not_if { node['fb_dnf']['modules'].empty? }
end

include_recipe 'fb_dnf::packages'
# Need RPMs installed before we can disable/enable the makecache timer
include_recipe 'fb_dnf::makecache'
