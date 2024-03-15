#
# Cookbook Name:: fb_systemd
# Recipe:: networkd
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

fb_helpers_gated_template '/etc/systemd/networkd.conf' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  allow_changes node.nw_changes_allowed?
  source 'systemd.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  variables(
    :config => 'networkd',
    :section => %w{Network DHCP},
  )
  notifies :restart, 'service[systemd-networkd.service]'
end

# We need systemd-networkd to wait for udev rules to run before starting at boot
wait_for_udev = <<~EOF
  [Unit]
  After=systemd-udev-settle.service
  Wants=systemd-udev-settle.service
EOF

fb_systemd_override 'systemd-networkd wait for udev' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  unit_name 'systemd-networkd.service'
  content wait_for_udev
  action :create
end

service 'systemd-networkd.socket' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  only_if { node['fb_systemd']['networkd']['use_networkd_socket_with_networkd'] }
  notifies :stop, 'service[systemd-networkd.service]', :before
  notifies :start, 'service[systemd-networkd.service]', :immediately
  action [:enable, :start]
end

service 'mask systemd-networkd.socket' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  not_if { node['fb_systemd']['networkd']['use_networkd_socket_with_networkd'] }
  service_name 'systemd-networkd.socket'
  action :mask
end

service 'disable systemd-networkd.socket' do
  not_if { node['fb_systemd']['networkd']['enable'] }
  service_name 'systemd-networkd.socket'
  action [:stop, :disable]
end

service 'systemd-networkd.service' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-networkd.service' do
  not_if { node['fb_systemd']['networkd']['enable'] }
  service_name 'systemd-networkd.service'
  action [:stop, :disable]
end

# Get networkd to block network-online.target until interfaces are up
service 'systemd-networkd-wait-online.service' do
  only_if { node['fb_systemd']['networkd']['enable'] }
  # This is a one-shot at boot time, no :start
  action :enable
end
