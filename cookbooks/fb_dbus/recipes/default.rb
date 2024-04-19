#
# Cookbook Name:: fb_dbus
# Recipe:: default
#
# Copyright (c) 2018-present, Facebook, Inc.
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

unless node.centos?
  fail 'fb_dbus only supports CentOS hosts'
end

unless node.systemd?
  fail 'fb_dbus only supports systemd hosts'
end

whyrun_safe_ruby_block 'validate dbus implementation' do
  block do
    impl = node['fb_dbus']['implementation']
    unless %w{dbus-daemon dbus-broker}.include?(impl)
      fail 'fb_dbus: invalid dbus implementation, only dbus-daemon and ' +
           'dbus-broker are supported'
    end
  end
end

include_recipe 'fb_dbus::packages'

directory '/usr/lib/systemd/scripts' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  owner node.root_user
  group node.root_group
  mode '0755'
end

# Drop in override to force a daemon-reload when dbus restarts (#10321854)
cookbook_file '/usr/lib/systemd/scripts/dbus-restart-hack.sh' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  owner node.root_user
  group node.root_group
  mode '0755'
end

fb_systemd_override 'dbus' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-daemon' }
  unit_name 'dbus.service'
  content({
            'Service' => {
              'ExecStartPost' =>
                '-/usr/lib/systemd/scripts/dbus-restart-hack.sh',
            },
          })
end

file '/usr/lib/systemd/scripts/dbus-restart-hack.sh' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-broker' }
  action :delete
end

fb_systemd_override 'remove dbus override' do
  only_if { node['fb_dbus']['implementation'] == 'dbus-broker' }
  override_name 'dbus'
  unit_name 'dbus.service'
  action :delete
end

fb_dbus_implementation 'setup dbus implementation' do
  implementation lazy { node['fb_dbus']['implementation'] }
end
