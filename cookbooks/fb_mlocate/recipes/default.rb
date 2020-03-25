# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_mlocate
# Recipe:: default
#
# Copyright (c) 2012-present, Facebook, Inc.
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
  fail 'fb_mlocate: this cookbook is only supported on Linux'
end

# mlocate should be available (along with our custom updatedb.conf
# file) if and only if it is specifically requested via
# node['fb_mlocate']['want_mlocate']

conf_path = '/etc/updatedb.conf'

include_recipe 'fb_mlocate::packages'

template conf_path do
  only_if { node['fb_mlocate']['want_mlocate'] }
  source 'updatedb.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

package 'remove mlocate' do
  not_if { node['fb_mlocate']['want_mlocate'] }
  package_name 'mlocate'
  action :remove
end

file "remove #{conf_path}" do
  not_if { node['fb_mlocate']['want_mlocate'] }
  path conf_path
  action :delete
end

# Blow away any .rpmnew or .rpmsave files
%w{new save}.each do |suffix|
  file "#{conf_path}.rpm#{suffix}" do
    action :delete
  end
end

if node.centos? && !node.centos6? && !node.centos7?
  systemd_unit 'mlocate-updatedb.timer' do
    only_if { node['fb_mlocate']['want_mlocate'] }
    action [:enable, :start]
  end
end
