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
       [RHEL, windows]'
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
  'rhel' => '/etc/fluent-bit/plugins.conf',
  'windows' => windows_drive + '\opt\fluent-bit\conf\plugins.conf',
)

parsers_file_path = value_for_platform_family(
  'rhel' => '/etc/fluent-bit/parsers.conf',
  'windows' => windows_drive + '\opt\fluent-bit\conf\parsers.conf',
)

main_file_path = value_for_platform_family(
  'rhel' => '/etc/fluent-bit/fluent-bit.conf',
  'windows' => windows_drive + '\opt\fluent-bit\conf\fluent-bit.conf',
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

include_recipe 'fb_fluentbit::fluent-bit_rhel' if node.rhel_family?
include_recipe 'fb_fluentbit::fluent-bit_windows' if node.windows?

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
    notifies :restart, 'service[fluent-bit]'
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
    notifies :restart, 'service[fluent-bit]'
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
    notifies :restart, 'service[fluent-bit]'
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
    notifies :restart, 'service[fluent-bit]'
  end
end

if node.windows?
  windows_service 'FluentBit' do
    if node['fb_fluentbit']['custom_svc_restart_command']
      restart_command node['fb_fluentbit']['custom_svc_restart_command']
    end
    action :nothing
  end

  # We've seen a bunch of chef failures around the next part failing because something
  # notified the service, but the service comes back in stop pending... this is because the
  # custom restart command doens't actually wait for the service to stop, presumably by design.
  # In fluentd, this was worked around by just killing it with fire if we got here, which...
  # isn't great.  Normally how we'd handle this, is by putting a bunch of retries on the service
  # start, but that's also not great because sometimes the service _does_ fail, at which point
  # you're waiting minutes for a chef error... but we _also_ know that if we're in stop_pending,
  # the service _was_ up,a nd is coming from a restart command, and hence the service _will_
  # be up again, so we can just not do this in that case... at the very worst, it'll pick
  # up next chef run, but that situation should never actually happen, and in reality it should
  # always come back.
  windows_service 'Keep Fluentbit Active' do
    service_name 'FluentBit'
    only_if { node['fb_fluentbit']['keep_alive'] }
    not_if do
      !::Win32::Service.exists?('fluentbit') ||
            ::Win32::Service.status('fluentbit').current_state.downcase == 'stop pending'
    end
    action [:enable, :start]
  end
else
  service 'fluent-bit' do
    action [:enable, :start]
  end
end
