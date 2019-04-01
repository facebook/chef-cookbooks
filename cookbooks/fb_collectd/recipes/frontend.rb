#
# Cookbook Name:: fb_collectd
# Recipe:: frontend
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

unless node.centos? || node.debian? || node.ubuntu?
  fail 'fb_collectd is only supported on CentOS, Debian or Ubuntu.'
end

case node['platform_family']
when 'rhel', 'fedora'
  conf = '/etc/collectd/collection.conf'
when 'debian'
  conf = '/etc/collection.conf'
end

package 'collectd-web' do
  # this is bundled in the main collectd-core package on debian
  not_if { node['platform_family'] == 'debian' }
  action :upgrade
end

template conf do
  source 'collection.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
