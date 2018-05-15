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

apache_version =
  case node['platform_family']
  when 'debian'
    case node['platform']
    when 'ubuntu'
      node['platform_version'].to_f >= 13.10 ? '2.4' : '2.2'
    when 'debian'
      node['platform_version'].to_f >= 8.0 ? '2.4' : '2.2'
    else
      '2.4'
    end
  when 'rhel'
    node['platform_version'].to_f >= 7.0 ? '2.4' : '2.2'
  end

confdir =
  case node['platform_family']
  when 'rhel'
    '/etc/httpd/conf.d'
  when 'debian'
    case apache_version
    when '2.2'
      '/etc/apache2/conf.d'
    when '2.4'
      '/etc/apache2/conf-enabled'
    end
  end

sitesdir = value_for_platform_family(
  'rhel' => confdir,
  'debian' => '/etc/apache2/sites-enabled',
)

moddir =
  case node['platform_family']
  when 'rhel'
    '/etc/httpd/conf.modules.d'
  when 'debian'
    case apache_version
    when '2.2'
      '/etc/apache2/modules-enabled'
    when '2.4'
      '/etc/apache2/mods-enabled'
    end
  end

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
  package_name lazy {
    pkgs + FB::Apache.get_module_packages(
      node['fb_apache']['modules'],
      node['fb_apache']['module_packages'],
    )
  }
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
  not_if { node.centos6? }
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[apache]'
end

template "#{sitesdir}/fb_sites.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[apache]'
end

template "#{confdir}/fb_apache.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[apache]'
end

service 'apache' do
  service_name svc
  action [:enable, :start]
end
