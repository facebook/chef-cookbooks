#
# Cookbook Name:: fb_yum_repos
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

unless node.centos? || node.fedora? || node.rocky?
  fail 'fb_yum_repos: this cookbook only supports CentOS, Fedora, and Rocky Linux'
end

execute 'clean yum metadata' do
  command "#{node.default_package_manager} clean metadata"
  action :nothing
end

# This is refreshing the internal chef caches.  It's a block of code which
# doesn't change the system state; that means it can be run safely, even in
# whyrun mode.
whyrun_safe_ruby_block 'clean chef yum metadata' do
  block do
    if node.default_package_manager == 'dnf'
      Chef::Provider::Package::Dnf::PythonHelper.instance.restart
    elsif node.default_package_manager == 'yum'
      Chef::Provider::Package::Yum::YumCache.instance.reload
    else
      fail 'fb_yum_repos[clean chef package metadata]: unknown package ' +
           "manager: #{node.default_package_manager}"
    end
  end
  action :nothing
end

directory '/etc/yum.repos.d' do
  owner node.root_user
  group node.root_group
  mode '0755'
end

fb_yum_repos 'manage repos' do
  only_if { node['fb_yum_repos']['manage_repos'] }
  notifies :run, 'execute[clean yum metadata]', :immediately
  notifies :run, 'whyrun_safe_ruby_block[clean chef yum metadata]', :immediately
end
