#
# Cookbook Name:: fb_collectd
# Recipe:: frontend
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
