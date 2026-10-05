#
# Cookbook:: fb_spf_engine
# Recipe:: default
#
# Copyright:: 2026-present, Meta Platforms, Inc. and affiliates.
# Copyright:: 2026-present, Phil Dibowitz
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

packages = value_for_platform_family(
  ['debian'] => %w{python3-spf-engine pyspf-milter},
  'default' => %w{pypolicyd-spf pypolicyd-spf-milter},
)

package 'spf-engine packages' do
  only_if { node['fb_spf_engine']['manage_packages'] }
  package_name packages
  action :upgrade
end

config_file = value_for_platform_family(
  ['debian'] => '/etc/pyspf-milter/pyspf-milter.conf',
  'default' => '/etc/python-policyd-spf/pyspf-milter.conf',
)

config_dir = ::File.dirname(config_file)

directory config_dir do
  owner node.root_user
  group node.root_group
  mode '0755'
end

template config_file do
  source 'pyspf-milter.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[pyspf-milter]'
end

service 'pyspf-milter' do
  action [:enable, :start]
end
