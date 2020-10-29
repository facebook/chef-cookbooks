#
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

# configs location
CONF_FILE_NAME = '/etc/td-agent-bit/td-agent-bit.conf'.freeze
PLUGIN_FILE_NAME = '/etc/td-agent-bit/plugins.conf'.freeze
# fb_fluentbit core rpm name
BASIC_PACKAGE_NAME = 'td-agent-bit'.freeze

SERVICE_NAME = 'td-agent-bit'.freeze

whyrun_safe_ruby_block 'validate fluentbit config' do
  block do
    FB::Fluentbit.valid_configuration?(node['fb_fluentbit']['plugins'])
    node['fb_fluentbit']['plugins'].keys.each do |plugin|
      node.default['fb_fluent']['plugins'][plugin]['plugin_config'] ||= {}
      FB::Fluentbit.valid_plugin?(node['fb_fluentbit']['plugins'][plugin])
      node.default['fb_fluentbit']['plugins'][plugin]['type'].upcase!
    end
  end
end

package BASIC_PACKAGE_NAME do
  action :upgrade
end

package 'fluentbit external plugins' do
  package_name lazy {
    node['fb_fluentbit']['plugins'].values.map { |p| p['package_name'] }.compact
  }
  action :upgrade
end

template PLUGIN_FILE_NAME do # ~FB031
  action :create
  source 'plugins.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[#{SERVICE_NAME}]", :delayed
end

remote_file CONF_FILE_NAME do
  only_if { node['fb_fluentbit']['external_config_url'] }
  source lazy { node['fb_fluentbit']['external_config_url'] }
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  notifies :restart, "service[#{SERVICE_NAME}]", :delayed
end

template CONF_FILE_NAME do # ~FB031
  not_if { node['fb_fluentbit']['external_config_url'] }
  action :create
  source 'conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  notifies :restart, "service[#{SERVICE_NAME}]", :delayed
end

service SERVICE_NAME do
  action [:enable, :start]
end
