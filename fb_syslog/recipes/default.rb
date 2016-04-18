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

package_name = service_name = 'rsyslog'
config_file = '/etc/rsyslog.conf'

if node.macosx?
  service_name = 'com.apple.syslogd'
  config_file = '/etc/syslog.conf'
elsif node.yocto?
  service_name = 'rsyslogd'
  config_file = '/etc/syslog.conf'
end

if node.centos?
  package 'rsyslog-relp' do
    only_if { node['fb_syslog']['rsyslog_relp_tls'] }
    action :upgrade
  end

  directory '/var/spool/rsyslog' do
    user 'root'
    group 'root'
    mode '0700'
  end

  package package_name do
    not_if { node.yocto? }
    action :upgrade
  end

  template '/etc/sysconfig/rsyslog' do
    source 'rsyslog-sysconf.erb'
    user 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[rsyslog]'
  end

end

template config_file do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[#{service_name}]"
end

actions = [:start]
actions << :enable unless node.macosx?
support = { :status => true }
# rsyslog, unlike sysklogd, needs a full restart to pick up configs, because
# it uses HUP (i.e. reload) only to close descriptors (i.e. logrotate).  Given
# that sysklogd is going to be out of the equation and it would be the only
# one using a reload action for picking up configs, I'm defaulting to
# :restart.
support.merge({ :restart => true, :reload => true }) unless node.macosx?
support.merge({ :status => false, :reload => false }) if node.yocto?
service service_name do
  supports support
  action actions
end
