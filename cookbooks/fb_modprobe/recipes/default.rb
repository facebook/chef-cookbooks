#
# Cookbook Name:: fb_modprobe
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

# for things to notify
ohai 'reload kernel' do
  plugin 'kernel'
  action :nothing
end

directory '/etc/modprobe.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

%w{
  /etc/modprobe.d/blacklist
  /etc/modprobe.d/blacklist.rpmsave
}.each do |path|
  file path do
    action :delete
  end
end

template '/etc/modprobe.d/fb_modprobe.conf' do
  source 'fb_modprobe.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

if node.systemd?
  template '/etc/modules-load.d/chef.conf' do
    source 'modules-load.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, 'execute[load modules]'
  end
else
  directory '/etc/sysconfig/modules' do
    only_if { node.centos? && !node.systemd? }
    owner 'root'
    group 'root'
    mode '0755'
  end

  template '/etc/sysconfig/modules/fb.modules' do
    only_if { node.centos? && !node.systemd? }
    source 'fb.modules.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
end
