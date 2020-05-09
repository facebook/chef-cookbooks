#
# Cookbook:: fb_stunnel
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

packagename = value_for_platform_family(
  ['rhel', 'fedora'] => 'stunnel',
  'debian' => 'stunnel4',
)

sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => File.join('/etc/sysconfig/', packagename),
  'debian' => File.join('/etc/default/', packagename),
)

package packagename do
  action :upgrade
end

# Debian/Ubuntu has a unit file
if node.centos? && node.systemd?
  cookbook_file '/etc/systemd/system/stunnel.service' do
    source 'stunnel.service'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
  end
end

template '/etc/stunnel/fb_tunnel.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[stunnel]'
end

if node.debian? || node.ubuntu?
  whyrun_safe_ruby_block 'merge enables' do
    block do
      node.default['fb_stunnel']['sysconfig']['enabled'] =
        node['fb_stunnel']['enable'] ? 1 : 0
    end
  end
end

template sysconfig do # ~FB031
  source 'sysconfig.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[stunnel]'
end

fb_stunnel_create_certs 'do it' do
  only_if { node['fb_stunnel']['enable'] }
end

service 'stunnel' do
  only_if do
    node['fb_stunnel']['enable'] && !node['fb_stunnel']['config'].empty?
  end
  service_name packagename
  action [:enable, :start]
end

service 'disable stunnel' do
  not_if { node['fb_stunnel']['enable'] }
  service_name packagename
  action [:stop, :disable]
end
