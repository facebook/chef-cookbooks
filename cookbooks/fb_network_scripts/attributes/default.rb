# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

primary_int = 'eth0'

# populate default ring_params
ring_params = {}
if node.linux?
  node['network']['interfaces'].to_hash.each do |iface, config|
    vals = config['ring_params']
    next unless vals

    ring_params[iface] = {
      'max_rx' => vals['max_rx'],
      'max_tx' => vals['max_tx'],
    }
  end
end

default['fb_network_scripts'] = {
  'manage_packages' => true,
  'primary_interface' => primary_int,
  'interfaces' => {
    primary_int => {},
  },
  'routing' => {
    'extra_routes' => {},
  },
  'ring_params' => ring_params,
  'ifup' => {
    'ethtool' => [],
    'extra_commands' => [],
    'sysctl' => {},
  },
  'allow_dynamic_addresses' => true,
  'enable_tun' => false,
  'enable_bridge_filter' => false,
  'linkdelay' => 0,
  'network_changes_allowed_method' => nil,
  'interface_change_allowed_method' => nil,
  'interface_start_allowed_method' => nil,

  # Internal attributes, do not use
  '_rerun_ifup_local' => false,
}
