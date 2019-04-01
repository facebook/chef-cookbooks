# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_iptables
# Recipe:: packages
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

packages = ['iptables']
if node.centos6?
  packages << 'iptables-ipv6'
elsif node.ubuntu?
  packages << 'iptables-persistent'
else
  packages << 'iptables-services'
end

package packages do
  only_if { node['fb_iptables']['manage_packages'] }
  action :upgrade
  notifies :run, 'execute[reload iptables]'
  notifies :run, 'execute[reload ip6tables]'
end

execute 'reload iptables' do
  only_if { node['fb_iptables']['enable'] }
  command '/usr/sbin/fb_iptables_reload 4 reload'
  action :nothing
  subscribes :run, 'package[osquery]'
end

## ip6tables ##
execute 'reload ip6tables' do
  only_if { node['fb_iptables']['enable'] }
  command '/usr/sbin/fb_iptables_reload 6 reload'
  action :nothing
end
