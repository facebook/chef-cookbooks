# Cookbook Name:: fb_iptables
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

unless node.centos? || node.fedora? || node.ubuntu?
  fail 'fb_iptables is only supported on CentOS, Fedora, and Ubuntu'
end

services = value_for_platform(
  'ubuntu' => { :default => %w{netfilter-persistent} },
  :default => %w{iptables ip6tables},
)
iptables_config_dir = value_for_platform(
  'ubuntu' => { :default => '/etc/iptables' },
  :default => '/etc/sysconfig',
)
iptables_rule_file = value_for_platform(
  'ubuntu' => { :default => 'rules.v4' },
  :default => 'iptables',
)
ip6tables_rule_file = value_for_platform(
  'ubuntu' => { :default => 'rules.v6' },
  :default => 'ip6tables',
)
iptables_rules = ::File.join(iptables_config_dir, iptables_rule_file)
ip6tables_rules = ::File.join(iptables_config_dir, ip6tables_rule_file)

# firewalld/ufw conflicts with direct iptables management
conflicting_package = value_for_platform(
  'ubuntu' => { :default => 'ufw' },
  :default => 'firewalld',
)

service conflicting_package do
  only_if { node['fb_iptables']['manage_packages'] }
  action [:stop, :disable]
end

package conflicting_package do
  only_if { node['fb_iptables']['manage_packages'] }
  options '--exclude kernel*' if node.fedora?
  action :remove
end

include_recipe 'fb_iptables::packages'

services.each do |svc|
  service svc do
    only_if { node['fb_iptables']['enable'] }
    action :enable
  end

  service "disable #{svc}" do
    not_if { node['fb_iptables']['enable'] }
    service_name svc
    action :disable
  end
end

## iptables ##
template '/etc/fb_iptables.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :iptables_config_dir => iptables_config_dir,
    :iptables_rules_file => iptables_rule_file,
    :ip6tables_rules_file => ip6tables_rule_file,
  )
end

# DO NOT MAKE THIS A TEMPLATE! USE THE CONFIG FILE TEMPLATED ABOVE!!
cookbook_file '/usr/sbin/fb_iptables_reload' do
  source 'fb_iptables_reload.sh'
  owner 'root'
  group 'root'
  mode '0755'
end

template "#{iptables_config_dir}/iptables-config" do
  owner 'root'
  group 'root'
  mode '0640'
  variables(:ipversion => 4)
end

template iptables_rules do
  source 'iptables.erb'
  owner 'root'
  group 'root'
  mode '0640'
  variables(:ip => 4)
  verify do |path|
    # iptables-restore and ip6tables-restore load the kernel modules
    # for iptables, even in test mode.  To avoid this, skip
    # verification if the modules aren't loaded.  This moves a
    # verification time failure to a runtime failure (but only when
    # moving from "no rules" to any rules; otherwise we still verify
    # every time).
    if FB::Iptables.iptables_active?(4)
      Mixlib::ShellOut.new(
        "/sbin/iptables-restore --test #{path}",
      ).run_command.exitstatus.zero?
    else
      true
    end
  end
  notifies :run, 'execute[reload iptables]', :immediately
end

template "#{iptables_config_dir}/ip6tables-config" do
  source 'iptables-config.erb'
  owner 'root'
  group 'root'
  mode '0640'
  variables(:ipversion => 6)
end

template ip6tables_rules do
  source 'iptables.erb'
  owner 'root'
  group 'root'
  mode '0640'
  variables(:ip => 6)
  verify do |path|
    # See comment ip iptables_rules
    if FB::Iptables.iptables_active?(6)
      Mixlib::ShellOut.new(
        "/sbin/ip6tables-restore --test #{path}",
      ).run_command.exitstatus.zero?
    else
      true
    end
  end
  notifies :run, 'execute[reload ip6tables]', :immediately
end
