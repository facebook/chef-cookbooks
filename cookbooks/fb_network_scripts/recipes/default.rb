#
# Cookbook Name:: fb_network_scripts
# Recipe:: default
#
# Copyright (c) 2012-present, Facebook, Inc.
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

net_svc_name = value_for_platform(
  ['centos', 'redhat', 'fedora', 'arista_eos'] => { 'default' => 'network' },
)

unless net_svc_name
  fail "fb_network_scripts: unsupported platform #{node['platform']}, cannot " +
       'continue'
end

# Action is nothing because we don't need chef to make sure this is running
# it's just here so we can call restart
service 'network' do
  only_if { node.nw_changes_allowed? }
  service_name net_svc_name
  supports :restart => true
  action :nothing
end

fb_network_scripts_request_nw_changes 'manage' do
  action :nothing
  delayed_action :cleanup_signal_files_when_no_change_required
end

template '/etc/sysconfig/network' do
  only_if { ['rhel', 'fedora'].include?(node['platform_family']) }
  source 'network.erb'
  owner 'root'
  group 'root'
  mode '0644'
  if node.firstboot_any_phase?
    notifies :restart, 'service[network]'
  end
end

include_recipe 'fb_network_scripts::packages'

fb_modprobe_module 'br_netfilter' do
  only_if { node['fb_network_scripts']['enable_bridge_filter'] }
  action :load
end

if node.centos?
  directory '/dev/net' do
    only_if { node['fb_network_scripts']['enable_tun'] }
    owner 'root'
    group 'root'
    mode '0755'
  end

  execute 'create_dev_net_tun' do
    only_if { node['fb_network_scripts']['enable_tun'] }
    not_if { File.chardev?('/dev/net/tun') }
    creates '/dev/net/tun'
    command 'mknod /dev/net/tun c 10 200'
  end
else # Not a centos box
  whyrun_safe_ruby_block 'test tun sanity' do
    only_if { node['fb_network_scripts']['enable_tun'] }
    block do
      fail 'fb_network_scripts: Tunneling is only supported on CentOS'
    end
  end
end

# Workaround for https://github.com/fedora-sysv/initscripts/issues/296
cookbook_file '/sbin/ifup-pre-local' do
  source 'ifup-pre-local'
  owner 'root'
  group 'root'
  mode '0755'
end

# For interfaces where we could read the ring buffer settings, check that
# they are maxed out and increase them if necessary. Only eth interfaces are
# supported and we skip them if they're not up. mlx nics can hang unless the
# driver is >= v1.5.10 (newer kernels) so skip ones that are unsafe.
whyrun_safe_ruby_block 'setup ring params' do
  only_if { node.linux? }
  block do
    node['fb_network_scripts']['ring_params'].to_hash.each do |iface, config|
      next unless config

      node.default['fb_network_scripts']['ifup']['ethtool'] << {
        'interface' => iface,
        'subcommand' => '-G',
        'field' => 'rx',
        'check_field' => 'RX',
        'check_pipe' => 'grep Current -A 100',
        'value' => config['max_rx'],
      }
      node.default['fb_network_scripts']['ifup']['ethtool'] << {
        'interface' => iface,
        'subcommand' => '-G',
        'field' => 'tx',
        'check_field' => 'TX',
        'check_pipe' => 'grep Current -A 100',
        'value' => config['max_tx'],
      }
    end
  end
end

if node.centos?
  %w{
    NetworkManager
  }.each do |pkg|
    service pkg do
      action [:disable, :stop]
    end
  end

  service 'rdisc' do
    action [:stop, :disable]
  end
end

whyrun_safe_ruby_block 'validate v6 secondaries' do
  block do
    node['fb_network_scripts']['interfaces'].to_hash.each do |iface, conf|
      conf['v6secondaries']&.each do |addr|
        unless addr.include?('/')
          fail 'fb_network_scripts: You must specify a netmask to address' +
            " in v6secondaries (#{iface})"
        end
      end
    end
  end
end

# Setups up networking files, and will internally bounce interfaces
# that need it, unless we plan to restart networking
fb_network_scripts 'interface_files'

# This dance is so that other recipes that might be adding ifup commands are
# able to force a reload when their scripts are updated
whyrun_safe_ruby_block 'trigger re-run of ifup-local' do
  block do
    node.default['fb_network_scripts']['_rerun_ifup-local'] = true
  end
  action :nothing
end

# This has to be processed *after* the fb_network_scripts provider as it reads
# the node['fb_network_scripts']['ifup']['sysctl'] attribute, which is set by
# the provider.
template '/sbin/ifup-local' do
  source 'ifup-local.erb'
  owner 'root'
  group 'root'
  mode '0755'
  notifies :run, 'whyrun_safe_ruby_block[trigger re-run of ifup-local]', :immediately
end

execute 're-run ifup-local' do
  only_if { node['fb_network_scripts']['_rerun_ifup-local'] }
  command '/sbin/ifup-local all'
end

# This is done in ifup-local above, (which runs both at boot and whenever
# the script changes), but it's still possible to miss hosts (e.g., if someone
# manually changes the setting). So keep this block in just in case
node['network']['interfaces'].to_hash.each_key do |iface|
  next if iface == 'lo'

  execute "set RX/TX ring parameters for #{iface}" do
    only_if do
      # network is only available on Linux
      node.linux? &&
      # make sure this is a physical interface in the up state
      node['network']['interfaces'][iface]['flags'] &&
      node['network']['interfaces'][iface]['flags'].include?('UP') &&
      # only run if something needs to be changed
      node['network']['interfaces'][iface]['ring_params'] &&
      node['fb_network_scripts']['ring_params'][iface] &&
      (node['fb_network_scripts']['ring_params'][iface]['max_rx'] !=
         node['network']['interfaces'][iface]['ring_params']['current_rx'] ||
       node['fb_network_scripts']['ring_params'][iface]['max_tx'] !=
         node['network']['interfaces'][iface]['ring_params']['current_tx'])
    end
    # this is done at runtime because not all interfaces have ring_params, so
    # it should only be evaluated after the only_if clears
    command lazy {
      "ethtool -G #{iface} " +
      "rx #{node['fb_network_scripts']['ring_params'][iface]['max_rx']} " +
      "tx #{node['fb_network_scripts']['ring_params'][iface]['max_tx']} "
    }
    # ethtool returns 80 if there was nothing to change
    returns [0, 80]
  end
end

# Conditionally fail if a dynamic address was found on one of the interfaces.
# Examples of dynamic addresses include SLAAC or DHCP(v6).
whyrun_safe_ruby_block 'validate dynamic address' do
  not_if { node['fb_network_scripts']['allow_dynamic_addresses'] }
  block do
    node['network']['interfaces'].each do |if_str, if_data|
      next unless if_data['addresses']
      if_data['addresses'].each do |addr_str, addr_data|
        next unless addr_data['family'] == 'inet6'
        if Array(addr_data['tags']).include?('dynamic')
          fail "fb_network_scripts: interface #{if_str} has a dynamic " +
               "address: #{addr_str}."
        end
      end
    end
  end
end
