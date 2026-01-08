#
# Cookbook:: fb_opendkim
# Recipe:: default
#
# Copyright:: 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright:: 2025-present, Phil Dibowitz
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

packages = %w{
  opendkim
  opendkim-tools
}

package 'opendkim packages' do
  only_if { node['fb_opendkim']['manage_packages'] }
  package_name packages
  action :upgrade
end

template '/etc/opendkim.conf' do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[opendkim]'
end

sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/sysconfig/opendkim',
  ['debian'] => '/etc/default/opendkim',
)

template sysconfig do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[opendkim]'
end

service 'opendkim' do
  action [:enable, :start]
end
