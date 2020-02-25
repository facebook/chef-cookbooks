# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_hostname
# Recipe:: default
#
# Copyright (c) 2019-present, Facebook, Inc.
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

unless node.linux? || node.macos?
  fail 'fb_hostname: only Linux and MacOS are supported!'
end

execute 'set static hostname' do
  only_if do
    node.systemd? && node['hostnamectl'] && node['fb_hostname']['hostname'] &&
      node['fb_hostname']['hostname'] != node['hostnamectl']['static_hostname']
  end
  command lazy {
    "/bin/hostnamectl set-hostname #{node['fb_hostname']['hostname']} --static"
  }
end

execute 'set pretty hostname' do
  only_if do
    node.systemd? && node['hostnamectl'] && node['fb_hostname']['pretty'] &&
      node['fb_hostname']['pretty_hostname'] !=
        node['hostnamectl']['pretty_hostname']
  end
  command lazy {
    "/bin/hostnamectl set-hostname #{node['fb_hostname']['pretty_hostname']}" +
    '--pretty'
  }
end

file '/etc/hostname' do
  only_if { node.linux? && node['fb_hostname']['hostname'] }
  owner 'root'
  group 'root'
  mode '0644'
  content lazy { node['fb_hostname']['hostname'] }
end

%w{
  HostName
  ComputerName
}.each do |key|
  execute "set #{key}" do
    only_if do
      node.macos? && node['fb_hostname']['hostname'] &&
        node['fb_hostname']['hostname'] != node['hostname']
    end
    command lazy {
      "/usr/sbin/scutil --set #{key} #{node['fb_hostname']['hostname']}"
    }
  end
end
