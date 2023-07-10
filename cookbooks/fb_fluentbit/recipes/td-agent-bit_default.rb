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

unless node.rhel_family? || node.windows?
  fail 'fb_fluentbit: unsupported platform. The list of supported platforms is
       [RHEL_Family, windows]'
end
whyrun_safe_ruby_block 'validate fluentbit config' do
  block do
    parsers = FB::Fluentbit.parsers_from_node(node)
    parsers.each(&:validate)

    multiline_parsers = FB::Fluentbit.multiline_parsers_from_node(node)
    multiline_parsers.each(&:validate)

    external_plugins = FB::Fluentbit.external_plugins_from_node(node)
    external_plugins.each(&:validate)

    FB::Fluentbit.plugins_from_node(node).each do |plugin|
      plugin.validate(parsers)
    end
  end
end

windows_drive = ENV['SYSTEMDRIVE'] || 'C:'

plugins_file_path = value_for_platform_family(
  'rhel' => '/etc/td-agent-bit/plugins.conf',
  'windows' => windows_drive + '\opt\td-agent-bit\conf\plugins.conf',
)

parsers_file_path = value_for_platform_family(
  'rhel' => '/etc/td-agent-bit/parsers.conf',
  'windows' => windows_drive + '\opt\td-agent-bit\conf\parsers.conf',
)

main_file_path = value_for_platform_family(
  'rhel' => '/etc/td-agent-bit/td-agent-bit.conf',
  'windows' => windows_drive + '\opt\td-agent-bit\conf\fluent-bit.conf',
)

# Create a directory for runtime state
state_dir = value_for_platform_family(
  'rhel' => '/var/fluent-bit',
  'windows' => windows_drive + '\ProgramData\fluent-bit',
)

directory 'runtime state directory' do
  action :create
  path state_dir
  if node.windows?
    rights :full_control, 'Administrators'
  else
    owner 'root'
    group 'root'
    mode '0755'
  end
end

include_recipe 'fb_fluentbit::td-agent-bit_rhel' if node.rhel_family?
include_recipe 'fb_fluentbit::td-agent-bit_windows' if node.windows?

template 'plugins config' do
  action :create
  source 'plugins.conf.erb'
  path plugins_file_path
  if node.windows?
    rights :full_control, 'Administrators'
    notifies :restart, 'windows_service[FluentBit]'
  else
    owner 'root'
    group 'root'
    mode '0600'
    notifies :restart, 'service[td-agent-bit]'
  end
end

template 'parsers config' do
  action :create
  source 'parsers.conf.erb'
  path parsers_file_path
  if node.windows?
    rights :full_control, 'Administrators'
    notifies :restart, 'windows_service[FluentBit]'
  else
    owner 'root'
    group 'root'
    mode '0600'
    notifies :restart, 'service[td-agent-bit]'
  end
end

remote_file 'remote config' do
  only_if { node['fb_fluentbit']['external_config_url'] }
  action :create
  source lazy { node['fb_fluentbit']['external_config_url'] }
  path main_file_path
  if node.windows?
    rights :full_control, 'Administrators'
    notifies :restart, 'windows_service[FluentBit]'
  else
    owner 'root'
    group 'root'
    mode '0600'
    notifies :restart, 'service[td-agent-bit]'
  end
end

template 'local config' do
  not_if { node['fb_fluentbit']['external_config_url'] }
  action :create
  source 'conf.erb'
  path main_file_path
  if node.windows?
    rights :full_control, 'Administrators'
    notifies :restart, 'windows_service[FluentBit]'
  else
    owner 'root'
    group 'root'
    mode '0600'
    notifies :restart, 'service[td-agent-bit]'
  end
end

if node.windows?
  windows_service 'FluentBit' do
    if node['fb_fluentbit']['custom_svc_restart_command']
      restart_command node['fb_fluentbit']['custom_svc_restart_command']
    end
    action :nothing
  end

  windows_service 'Keep Fluentbit Active' do
    service_name 'FluentBit'
    only_if { node['fb_fluentbit']['keep_alive'] }
    action [:enable, :start]
  end
else
  service 'td-agent-bit' do
    action [:enable, :start]
  end
end
