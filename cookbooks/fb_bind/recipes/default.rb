#
# Cookbook:: fb_bind
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

conf = ::File.join(FB::Bind::CONFIG_DIR, 'named.conf')
svc = 'named'
if rpm_based?
  pkgs = %w{
    bind
    bind-utils
  }
  zones_dir = '/var/named'
  usrgrp = 'named'
  rndc_key = '/etc/rndc.key'
  sysconfig = '/etc/sysconfig/named'
elsif debian?
  pkgs = %w{
    bind9
    bind9-host
    bind9-utils
    bind9-dnsutils
  }
  zones_dir = '/etc/bind'
  usrgrp = 'bind'
  rndc_key = '/etc/bind/rndc.key'
  sysconfig = '/etc/default/named'
end

package 'bind packages' do
  only_if { node['fb_bind']['manage_packages'] }
  package_name pkgs
  action :upgrade
  notifies :restart, 'service[bind]'
end

whyrun_safe_ruby_block 'validate sysconfig' do
  block do
    # remove improperly cased keys
    node['fb_bind']['sysconfig'].keys.each do |key|
      unless key == key.downcase
        Chef::Log.warn(
          "fb_bind: Removing #{key} from `node['fb_bind']['sysconfig'] as" +
          ' it is not lowercase. Please use all lowercase to prevent' +
          ' clobbering values when we upcase',
        )
        node.rm(:fb_bind, :sysconfig, key)
      end
    end

    # If we're on a redhat-like OS, then we must define $NAMEDCONF which
    # is used by their unitfile. We must ALSO ensure '-c' was not used in
    # $OPTIONS as that will break things, please we want to force the path
    # to the config.
    if rpm_based?
      node.default['fb_bind']['sysconfig']['namedconf'] = conf
      if node['fb_bind']['sysconfig']['options'] =~ /-c /
        fail 'fb_bind: You cannot include -c in' +
          " `node['fb_bind']['sysconfig']['options']`, it will break the" +
          ' unitfile. Further, this cookbook enforces a specific path to' +
          ' the configuration file. Please remove.'
      end
    end
  end
end

template sysconfig do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[bind]'
end

whyrun_safe_ruby_block 'conditionally populate empty rfc1918 zones' do
  only_if { node['fb_bind']['empty_rfc1918_zones'] }
  block { FB::Bind.populate_empty_rfc1918_zones(node) }
end

whyrun_safe_ruby_block 'validate config' do
  block do
    if node['fb_bind']['config']['zone'] ||
        node['fb_bind']['config']['zones']
      die "Zone(s) keyword found under `node['fb_bind']['config']`, please" +
        " use `node['fb_bind']['zones']`."
    end
  end
end

directory FB::Bind::CONFIG_DIR do
  owner usrgrp
  group usrgrp
  mode '02755'
end

template conf do
  owner node.root_user
  group usrgrp
  mode '0640'
  variables({ :zones_dir => zones_dir })
  verify 'named-checkconf %{path}'
  notifies :restart, 'service[bind]'
end

primary_dir = ::File.join(zones_dir, 'primary')
directory primary_dir do
  owner node.root_group
  group usrgrp
  mode '0755'
end

fb_bind_zonefiles 'doit' do
  zones_dir zones_dir
  group usrgrp
  notifies :reload, 'service[bind]'
end

execute 'initialize rndc' do
  creates rndc_key
  command 'rndc-confgen -a'
  notifies :restart, 'service[bind]'
end

service 'bind' do
  service_name svc
  action [:enable, :start]
end

fb_bind_persist_stable_resolve_cache 'doit'
