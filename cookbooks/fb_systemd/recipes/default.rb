#
# Cookbook Name:: fb_systemd
# Recipe:: default
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

# the resources for reloading systemd are useful, even if node.systemd?
# returns false. This happens when using this cookbook to build a container
# that is not booted.
include_recipe 'fb_systemd::reload'

unless node.systemd?
  fail 'fb_systemd is only available on systemd-enabled hosts'
end

case node['platform_family']
when 'rhel', 'fedora'
  systemd_prefix = '/usr'
when 'debian'
  systemd_prefix = ''
else
  fail 'fb_systemd is not supported on this platform.'
end

include_recipe 'fb_systemd::default_packages'

template '/etc/systemd/system.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'system',
    :section => 'Manager',
  )
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
end

template '/etc/systemd/user.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'user',
    :section => 'Manager',
  )
  notifies :run, 'fb_systemd_reload[all user instances]', :immediately
end

template '/etc/systemd/coredump.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'coredump',
    :section => 'Coredump',
  )
end

unless node.container?
  include_recipe 'fb_systemd::udevd'
end
include_recipe 'fb_systemd::journald'
include_recipe 'fb_systemd::journal-gatewayd'
include_recipe 'fb_systemd::journal-remote'
include_recipe 'fb_systemd::journal-upload'
include_recipe 'fb_systemd::logind'
include_recipe 'fb_systemd::networkd'
include_recipe 'fb_systemd::resolved'
include_recipe 'fb_systemd::timesyncd'
include_recipe 'fb_systemd::boot'

execute 'process tmpfiles' do
  command lazy {
    "#{systemd_prefix}/bin/systemd-tmpfiles --create" +
      node['fb_systemd']['tmpfiles_excluded_prefixes'].
      map { |x| " --exclude-prefix=#{x}" }.
      join
  }
  # it returns 65 if it had to ignore some lines, which seems to happen
  # quite often on initial setup
  if node.firstboot_any_phase?
    returns [0, 65]
  end
  action :nothing
end

template '/etc/tmpfiles.d/chef.conf' do
  source 'tmpfiles.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[process tmpfiles]'
end

execute 'load modules' do
  command "#{systemd_prefix}/lib/systemd/systemd-modules-load"
  action :nothing
end

directory '/etc/systemd/system-preset' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/systemd/system-preset/00-fb_systemd.preset' do
  source 'preset.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory '/etc/systemd/user/default.target.wants' do
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'set default target' do
  only_if do
    current = Mixlib::ShellOut.new('systemctl get-default').run_command.
              stdout.strip
    is_ignored = node['fb_systemd']['ignore_targets'].include?(current)
    is_supported = FB::Version.new(node['packages']['systemd'][
      'version']) >= FB::Version.new('205')
    is_supported && !is_ignored &&
      current != node['fb_systemd']['default_target']
  end
  command lazy {
    "systemctl set-default #{node['fb_systemd']['default_target']}"
  }
end

link '/etc/systemd/system/default.target' do
  only_if do
    FB::Version.new(node['packages']['systemd'][
      'version']) < FB::Version.new('205')
  end
  to lazy {
    "/lib/systemd/system/#{node['fb_systemd']['default_target']}.target"
  }
end
