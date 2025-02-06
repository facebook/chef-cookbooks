# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_chrony
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

if node.rhel_family? || node.fedora_family?
  chrony_svc = 'chronyd'
  chrony_conf = '/etc/chrony.conf'
  chrony_user = 'chrony'
  chrony_group = 'chrony'
elsif node.debian_family?
  chrony_svc = 'chrony'
  chrony_conf = '/etc/chrony/chrony.conf'
  chrony_user = '_chrony'
  chrony_group = '_chrony'
else
  fail 'fb_chrony: unsupported platform, aborting!'
end

include_recipe 'fb_chrony::packages'

directory '/var/run/chrony' do
  owner chrony_user
  group chrony_group
  mode '0750'
end

template 'chrony.conf' do
  path chrony_conf
  source 'chrony.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[chrony]'
end

fb_systemd_override 'chronyd_override' do
  unit_name 'chronyd.service'
  content({
            'Service' => {
              'Restart' => 'always',
            },
          })
end

service 'chrony' do
  service_name chrony_svc
  action [:enable, :start]
  subscribes :restart, [
    'package[chrony]',
    'fb_systemd_override[chronyd_override]',
  ]
end
