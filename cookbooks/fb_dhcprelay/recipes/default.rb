#
# Cookbook:: fb_dhcprelay
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2025-present, Phil Dibowitz
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# When RHEL10 dropped ISC, they also dropped replay, which is a bummer.
# Requested EPEL10 branch in
# https://bugzilla.redhat.com/show_bug.cgi?id=2348940
if node.el_min_version?(10)
  fail 'fb_dhcprelay: RHEL/CentOS 10+ no longer includes DHCP Relay'
end

if fedora_derived?
  pkgs = %w{dhcp-relay}
  svc = 'dhcrelay'
  sysconfig = "/etc/sysconfig/#{svc}"
elsif debian?
  pkgs = %w{isc-dhcp-relay}
  svc = 'isc-dhcp-relay'
  sysconfig = "/etc/default/#{svc}"
end

package 'dhcp-relay packages' do
  only_if { node['fb_dhcprelay']['manage_packages'] }
  package_name pkgs
  action :upgrade
  notifies :restart, 'service[dhcprelay]'
end

whyrun_safe_ruby_block 'validate sysconfig' do
  block do
    node['fb_dhcprelay']['sysconfig'].each_key do |key|
      if key != key.downcase
        fail "fb_dhcprelay: Non-lowercase key #{key} found in " +
          'node["fb_dhcprelay"]["sysconfig"] - please use lowercase key names'
      end
    end
  end
end

template sysconfig do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_user
  mode '0644'
  notifies :restart, 'service[dhcprelay]'
end

if fedora_derived?
  fb_systemd_override 'add-configurability' do
    unit_name "#{svc}.service"
    content <<~UNIT
      [Service]
      EnvironmentFile=-#{sysconfig}
      ExecStart=
      ExecStart=/usr/sbin/dhcrelay -d --no-pid $OPTIONS $SERVERS
    UNIT
    notifies :restart, 'service[dhcprelay]'
  end
end

service 'dhcprelay' do
  service_name svc
  action [:enable, :start]
end
