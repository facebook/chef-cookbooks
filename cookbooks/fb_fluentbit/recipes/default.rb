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
    parsers = FB::Fluentbit.parsers_from_node(node)
    parsers.each(&:validate)

    external_plugins = FB::Fluentbit.external_plugins_from_node(node)
    external_plugins.each(&:validate)

    FB::Fluentbit.plugins_from_node(node).each do |plugin|
      plugin.validate(parsers)
    end
  end
end

package 'td-agent-bit' do
  only_if { node['fb_fluentbit']['manage_packages'] }
  action :upgrade
end

package 'fluentbit external plugins' do
  only_if { node['fb_fluentbit']['plugin_manage_packages'] }
  package_name lazy {
    FB::Fluentbit.external_plugins_from_node(node).map(&:package).sort.uniq
  }
  action :upgrade
end

template '/etc/td-agent-bit/plugins.conf' do
  action :create
  source 'plugins.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[td-agent-bit]'
end

template '/etc/td-agent-bit/parsers.conf' do
  action :create
  source 'parsers.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[td-agent-bit]'
end

remote_file 'remote config' do
  only_if { node['fb_fluentbit']['external_config_url'] }
  source lazy { node['fb_fluentbit']['external_config_url'] }
  path '/etc/td-agent-bit/td-agent-bit.conf'
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  notifies :restart, 'service[td-agent-bit]'
end

template 'local config' do
  not_if { node['fb_fluentbit']['external_config_url'] }
  action :create
  source 'conf.erb'
  path '/etc/td-agent-bit/td-agent-bit.conf'
  owner 'root'
  group 'root'
  mode '0600'
  notifies :restart, 'service[td-agent-bit]'
end

service 'td-agent-bit' do
  action [:enable, :start]
end
