#
# Cookbook Name:: fb_systemd
# Recipe:: resolved
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

template '/etc/systemd/resolved.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'resolved',
    :section => 'Resolve',
  )
  notifies :restart, 'service[systemd-resolved]'
end

# nss-resolve enables DNS resolution via the systemd-resolved DNS/LLMNR caching
# stub resolver. According to upstream this should replace the glibc "dns"
# resolver and is required for systemd-resolved to work. This block attempts
# to place the resolver between mymachines and myhostname as recommended by
# upstream.
whyrun_safe_ruby_block 'enable nss-resolve' do
  only_if do
    node['fb_systemd']['resolved']['enable'] &&
    node['fb_systemd']['resolved']['enable_nss_resolve']
  end
  block do
    node.default['fb_nsswitch']['databases']['hosts'].delete('dns')
    idx = node['fb_nsswitch']['databases']['hosts'].index('mymachines')
    if idx
      node.default['fb_nsswitch']['databases']['hosts'].insert(idx + 1,
                                                               'resolve')
    else
      idx = node['fb_nsswitch']['databases']['hosts'].index('myhostname')
      if idx
        node.default['fb_nsswitch']['databases']['hosts'].insert(idx - 1,
                                                                 'resolve')
      else
        node.default['fb_nsswitch']['databases']['hosts'] << 'resolve'
      end
    end
  end
end

service 'systemd-resolved' do
  only_if { node['fb_systemd']['resolved']['enable'] }
  subscribes :restart, 'package[systemd packages]', :immediately
  action [:enable, :start]
end

service 'disable systemd-resolved' do
  not_if { node['fb_systemd']['resolved']['enable'] }
  service_name 'systemd-resolved'
  action [:stop, :disable]
end
