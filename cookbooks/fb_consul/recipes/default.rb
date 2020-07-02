#
# Cookbook:: fb_consul
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

unless node.debian? || node.ubuntu?
  fail 'fb_consul: Used on unsupported platform!'
end

node.default['fb_iptables']['filter']['INPUT']['rules']['consul']['rules'] = [
  # Gossip protocol between agents and servers
  '-p tcp --dport 8301 -j ACCEPT',
  '-p udp --dport 8301 -j ACCEPT',
]

node.default['fb_users']['users']['consul'] = {
  'comment' => 'consul agent user',
  'home' => '/run/consul',
  'shell' => '/usr/sbin/nologin',
}

package 'consul' do
  only_if { node['fb_consul']['manage_packages'] }
  action :upgrade
  notifies :restart, 'service[consul]'
end

whyrun_safe_ruby_block 'validate config' do
  block do
    node['fb_consul']['config'].each_key do |key|
      if ['config-file', 'config-dir'].include?(key)
        fail "fb_consul::default: #{key} is not allowed in 'config'! " +
          'Please use "services" and "checks" to configure consul.'
      end
    end
  end
end

directory 'consul data dir' do
  only_if do
    node['fb_consul']['enable']
  end
  path lazy { node['fb_consul']['config']['data_dir'] }
  owner 'consul'
  group 'root'
  mode '0770'
end

directory '/etc/consul' do
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/etc/default/consul' do
  source 'consul.default'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/consul/consul-agent-ca.pem' do # ~FB032
  only_if { node['fb_consul']['certificate_cookbook'] }
  cookbook lazy { node['fb_consul']['certificate_cookbook'] }
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/consul/consul-agent-ca-key.pem' do # ~FB032
  only_if do
    node['fb_consul']['config']['server'] &&
    node['fb_consul']['certificate_cookbook']
  end
  cookbook lazy { node['fb_consul']['certificate_cookbook'] }
  owner 'consul'
  group 'root'
  mode '0600'
end

cookbook_file '/etc/consul/consul-server.pem' do # ~FB032
  only_if do
    node['fb_consul']['config']['server'] &&
    node['fb_consul']['certificate_cookbook']
  end
  cookbook lazy { node['fb_consul']['certificate_cookbook'] }
  source "consul-server-#{node['hostname']}.pem"
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/consul/consul-server-key.pem' do # ~FB032
  only_if do
    node['fb_consul']['config']['server'] &&
    node['fb_consul']['certificate_cookbook']
  end
  cookbook lazy { node['fb_consul']['certificate_cookbook'] }
  source "consul-server-key-#{node['hostname']}.pem"
  owner 'consul'
  group 'root'
  mode '0600'
end

whyrun_safe_ruby_block 'add crypto options' do
  only_if { node['fb_consul']['certificate_cookbook'] }
  block do
    node.default['fb_consul']['config']['ca_file'] =
      '/etc/consul/consul-agent-ca.pem'
    if node['fb_consul']['config']['server']
      node.default['fb_consul']['config']['cert_file'] =
        '/etc/consul/consul-server.pem'
      node.default['fb_consul']['config']['key_file'] =
        '/etc/consul/consul-server-key.pem'
    end
  end
end

template '/etc/consul/consul.json' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'consul.json.erb'
  verify '/usr/bin/consul validate %{path}'
  notifies :restart, 'service[consul]'
end

service 'consul' do
  only_if { node['fb_consul']['enable'] }
  action [:enable, :start]
end

service 'disable consul' do
  not_if { node['fb_consul']['enable'] }
  action [:stop, :disable]
end
