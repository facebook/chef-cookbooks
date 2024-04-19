#
# Cookbook Name:: fb_networkd
# Recipe:: default
#
# Copyright (c) 2021-present, Facebook, Inc.
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

unless node.systemd?
  fail 'fb_networkd: this cookbook is only supported on systemd hosts'
end

node.default['fb_systemd']['networkd']['enable'] = true

fb_networkd 'manage configuration' do
  # Trigger deferred actions (e.g. :restart)
  notifies :trigger, 'fb_networkd_notify[doit]'
  # Trigger service stops (and starts) around networkd changes
  notifies :stop, 'fb_networkd_notify[doit]', :before
  notifies :start, 'fb_networkd_notify[doit]'
end

fb_networkd_notify 'doit' do
  action :nothing
end

# Increase timeout to avoid conflicting with any start/restart calls.
# Yes this could be racy but if systemd-networkd takes more than 30 min to come
# up there are probably bigger issues.
# The other option is to gate this on whether systemd-networkd is running, but
# that could also be racy if configs were changed while systemd-networkd is
# restarting, and changes were not picked up. This seemed like the lesser of 2
# evils.
execute 'networkctl reload' do
  command '/bin/networkctl reload'
  action :nothing
  environment({ 'SYSTEMD_BUS_TIMEOUT' => '1800s' })
  notifies :trigger, 'fb_networkd_notify[doit]'
end

node['network']['interfaces'].to_hash.each_key do |iface|
  next if iface == 'lo'

  # Link configurations are configured by systemd-udevd (through the
  # net_setup_link builtin as mentioned in the systemd.link man page).
  # To re-apply link configurations, either an "add", "bind", or "move"
  # action must be sent on the device.
  # This should use `udevadm test-builtin` in the future but --action wasn't
  # added to builtins until
  # https://github.com/systemd/systemd/pull/20460.
  execute "udevadm trigger #{iface}" do
    command "/bin/udevadm trigger --action=add /sys/class/net/#{iface}"
    action :nothing
  end
end

fb_helpers_request_nw_changes 'manage' do
  action :nothing
  delayed_action :cleanup_signal_files_when_no_change_required
end

if node.centos?
  directory '/dev/net' do
    only_if { node['fb_networkd']['enable_tun'] }
    owner node.root_user
    group node.root_group
    mode '0755'
  end

  execute 'create_dev_net_tun' do
    only_if { node['fb_networkd']['enable_tun'] }
    not_if { File.chardev?('/dev/net/tun') }
    creates '/dev/net/tun'
    command 'mknod /dev/net/tun c 10 200'
  end
else # Not a centos box
  whyrun_safe_ruby_block 'test tun sanity' do
    only_if { node['fb_networkd']['enable_tun'] }
    block do
      fail 'fb_networkd: Tunneling is only supported on CentOS'
    end
  end
end

# Conditionally fail if a dynamic address was found on one of the interfaces.
# Examples of dynamic addresses include SLAAC or DHCP(v6).
whyrun_safe_ruby_block 'validate dynamic address' do
  not_if { node['fb_networkd']['allow_dynamic_addresses'] }
  block { node.validate_and_fail_on_dynamic_addresses }
end
