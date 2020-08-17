#
# Cookbook Name:: fb_ntp
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

include_recipe 'fb_ntp::packages'

service_name = value_for_platform(
  ['redhat', 'centos', 'fedora', 'suse', 'arista_eos'] =>
    { 'default' => 'ntpd' },
  ['mac_os_x'] => { 'default' => 'com.apple.timed' },
  'default' => 'ntpd',
)

if node.macos?
  include_recipe 'fb_ntp::macosx'
end

whyrun_safe_ruby_block 'enforce ACL hardening' do
  block do
    # Prepend this to whatever default the end-user overrode
    acl_entries = [
      'restrict default ignore',
      'restrict -6 default ignore',
      'restrict 127.0.0.1',
      'restrict -6 ::1',
    ]

    # Resolve chosen timesources and allow them
    node['fb_ntp']['servers'].each do |host|
      begin
        ips = Resolv.getaddresses(host)
        ips.each do |ip|
          dash6 = ''
          dash6 = '-6 ' if IPAddr.new(ip).ipv6?
          acl_entries << "restrict #{dash6}#{ip} ##{host}"
        end
      rescue Resolv::ResolvError
        Chef::Log.warn("fb_ntp: failed to resolve #{host}, skipping")
      end
    end

    node.default['fb_ntp']['acl_entries'] = acl_entries +
      node['fb_ntp']['acl_entries']
  end
end

template '/etc/ntp.conf' do
  source 'ntp.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[#{service_name}]"
end

file '/etc/ntp/step-tickers' do
  only_if { node.centos? }
  action :delete
end

template '/etc/sysconfig/ntpd' do
  only_if { node.centos? }
  source 'ntpd.erb'
  mode '0644'
  owner 'root'
  group 'root'
  notifies :restart, "service[#{service_name}]"
end

fb_systemd_override 'local' do
  only_if { node.systemd? }
  unit_name 'ntpd.service'
  content({
            'Service' => {
              'Restart' => 'always',
            },
          })
end

service service_name do
  action [:enable, :start]
end

# ntpdate is a service that should only run at boot, as that is the only time
# the clock will be off enough to need it.  Running it on a clock-stable system
# is kind of terrible, so there is no need to tell the service to restart when
# the config changes.
template '/etc/sysconfig/ntpdate' do
  only_if { node.centos? }
  source 'ntpdate.erb'
  mode '0644'
  owner 'root'
  group 'root'
end

# note: on first boot from provisioning, ntpdate will have already run by (at
# least) chef_bootstrap, so we do not need to :start it here, avoiding many
# problems with this fake service.
service 'ntpdate' do
  only_if { node.centos? }
  action [:enable]
end
