#
# Cookbook Name:: fb_apache
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

confdir = value_for_platform_family(
  'rhel' => '/etc/httpd/conf.d',
  'debian' => '/etc/apache2/conf.d',
)

sitesdir = value_for_platform_family(
  'rhel' => confdir,
  'debian' => '/etc/apache2/sites-enabled',
)

moddir = value_for_platform_family(
  'rhel' => '/etc/httpd/conf.modules.d',
  'debian' => '/etc/apache2/modules-enabled',
)

sysconfig = value_for_platform_family(
  'rhel' => '/etc/sysconfig/httpd',
  'debian' => '/etc/default/apache2',
)

pkgs = value_for_platform_family(
  'rhel' => ['httpd', 'mod_ssl'],
  'debian' => ['apache2'],
)

svc = value_for_platform_family(
  'rhel' => 'httpd',
  'debian' => 'apache2',
)

package pkgs do
  only_if { node['fb_apache']['manage_packages'] }
  action :upgrade
end

template sysconfig do
  source 'sysconfig.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apache]'
end

template "#{moddir}/fb_modules.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apache]'
end

template "#{sitesdir}/fb_sites.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apache]'
end

template "#{confdir}/fb_apache.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apache]'
end

service 'apache' do
  service_name svc
  action [:enable, :start]
end
