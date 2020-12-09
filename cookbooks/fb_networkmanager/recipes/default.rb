#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
# Copyright (c) 2020-present, Facebook, Inc.
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

unless node.ubuntu? || node.debian?
  fail 'fb_networkmanager: Only Ubuntu or Debian are currently supported'
end

if node['fb_users']
  vpnhome = '/var/lib/openvpn/chroot'
  FB::Users.initialize_group(node, 'nm-openvpn')
  node.default['fb_users']['users']['nm-openvpn'] = {
    'gid' => 'nm-openvpn',
    # If /var/lib/openvpn doesn't exist yet, we can't create it in time
    # but we want to create the user, so for the first run, create it
    # with /tmp
    'home' => ::File.directory?(vpnhome) ? vpnhome : '/tmp',
    'shell' => '/usr/sbin/nologin',
    'action' => :add,
  }
end

packages = %w{
  network-manager
  openvpn
  network-manager-openvpn-gnome
}

package packages do
  only_if do
    node['fb_networkmanager']['enable'] &&
      node['fb_networkmanager']['manage_packages']
  end
  action :upgrade
end

template '/etc/NetworkManager/NetworkManager.conf' do
  only_if { node['fb_networkmanager']['enable'] }
  owner 'root'
  group 'root'
  mode '0644'
  source 'nm.conf.erb'
  helper(:data) { node['fb_networkmanager']['config'] }

  # this is still compile time, but that's OK, if the user
  # is VPN'd at the beginning of the run, don't restart
  vpned = FB::Networkmanager.active_connections.any? do |_, conn|
    conn['type'] == 'vpn'
  end

  # NM is too stupid to resume VPN on a restart, so if we're VPN'd
  # do NOT restart and hope we pick up whatever we needed later
  if vpned
    Chef::Log.warn(
      'fb_networkmanager: NOT restarting NetworkManager because machine ' +
      'is connected to VPN',
    )
  else
    notifies :restart, 'service[NetworkManager]'
  end
end

fb_networkmanager_system_connections 'doit' do
  only_if do
    node['fb_networkmanager']['enable'] &&
    !node['fb_networkmanager']['system_connections'].empty?
  end
  notifies :run, 'execute[reload nm connections]', :immediately
end

execute 'reload nm connections' do
  command 'nmcli c reload'
  only_if { node['fb_networkmanager']['enable'] }
  action :nothing
end

service 'NetworkManager' do
  only_if { node['fb_networkmanager']['enable'] }
  action [:enable, :start]
  subscribes :restart, 'service[systemd-resolved]', :immediately
end

service 'disable NetworkManager' do
  not_if { node['fb_networkmanager']['enable'] }
  action [:stop, :disable]
end

package 'remove network-manager' do
  only_if do
    node['fb_networkmanager']['manage_packages'] &&
      !node['fb_networkmanager']['enable'] &&
      FB::Networkmanager.active_connections.empty?
  end
  package_name 'network-manager'
  action :remove
end
