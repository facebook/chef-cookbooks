#
# Cookbook Name:: fb_collectd
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

# TODO: Use fedora_derived?
if node.centos? || node.rhel? || node.fedora?
  pkg = 'collectd'
  conf = '/etc/collectd.conf'
  conf_d = '/etc/collectd.d'
# TODO use debian?
elsif node.debian? || node.ubuntu?
  pkg = 'collectd-core'
  conf = '/etc/collectd/collectd.conf'
  conf_d = '/etc/collectd/collectd.conf.d'
else
  fail 'fb_collectd is only Fedora-based and Debian-based distros'
end

package pkg do
  action :upgrade
end

template '/etc/default/collectd' do
  # TODO use debian?
  only_if { node.debian? || node.ubuntu? }
  source 'collectd.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[collectd]'
end

Dir.glob("#{conf_d}/*").each do |f|
  file f do
    action :delete
  end
end

template conf do
  source 'collectd.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[collectd]'
end

service 'collectd' do
  # do not start with an empty config
  not_if do
    node['fb_collectd']['globals'].empty? &&
      node['fb_collectd']['plugins'].empty?
  end
  action [:enable, :start]
end
