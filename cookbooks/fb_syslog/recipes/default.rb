#
# Cookbook Name:: fb_syslog
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

if (node.systemd? || node.macosx?) && !node['fb_syslog']['sysconfig'].empty?
  fail 'fb_syslog: sysconfig settings are not supported on systemd or OSX hosts'
end

package_name = service_name = 'rsyslog'
config_file = '/etc/rsyslog.conf'

if node.macosx?
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

package package_name do
  not_if { node.macosx? }
  action :upgrade
end

template config_file do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[#{service_name}]"
end

actions = []
actions << :enable unless node.macosx?
actions << :start

# workaround for https://github.com/systemd/systemd/issues/6338
link '/etc/systemd/system/multi-user.target.wants/rsyslog.service' do
  only_if { node.systemd? }
  to '/lib/systemd/system/rsyslog.service'
end

service service_name do
  action actions
end
