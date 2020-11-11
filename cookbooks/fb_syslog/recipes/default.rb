#
# Cookbook Name:: fb_syslog
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

if (node.systemd? || node.macos?) && !node['fb_syslog']['sysconfig'].empty?
  fail 'fb_syslog: sysconfig settings are not supported on systemd or OSX hosts'
end

service_name = 'rsyslog'
config_file = '/etc/rsyslog.conf'

if node.macos?
  service_name = 'com.apple.syslogd'
  config_file = '/etc/syslog.conf'
else
  sysconfig_path = value_for_platform_family(
    ['rhel', 'fedora'] => '/etc/sysconfig/rsyslog',
    'debian' => '/etc/default/sysconfig',
  )

  template sysconfig_path do
    not_if { node.systemd? }
    source 'rsyslog-sysconf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[rsyslog]'
  end

  file sysconfig_path do
    only_if { node.systemd? }
    action :delete
  end
end

if node.centos?
  # only rotate rsyslog stats logs if we have them
  node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
    'files' => ['/var/log/rsyslog-stats.log'],
    'overrides' => {
      'missingok' => true,
      'notifempty' => true,
    },
  }
  directory '/var/spool/rsyslog' do
    owner 'root'
    group 'root'
    mode '0700'
  end
end

include_recipe 'fb_syslog::packages'

template config_file do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[#{service_name}]"
end

service service_name do
  action :start
  subscribes :restart, 'package[rsyslog]'
  # within vagrant, sometimes rsyslog fails to restart the first time
  retries 5
  retry_delay 5
end
