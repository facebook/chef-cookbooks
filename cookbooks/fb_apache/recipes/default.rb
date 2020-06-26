#
# Cookbook Name:: fb_apache
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

if node.centos8?
  node.default['fb_apache']['module_packages']['wsgi'] =
    value_for_platform_family(
      'rhel' => 'python3-mod_wsgi',
    )
  node.default['fb_apache']['modules_mapping']['wsgi'] = 'mod_wsgi_python3.so'
else
  node.default['fb_apache']['module_packages']['wsgi'] =
    value_for_platform_family(
      'rhel' => 'mod_wsgi',
    )
  node.default['fb_apache']['modules_mapping']['wsgi'] = 'mod_wsgi.so'
end

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

[moddir, sitesdir, confdir].uniq.each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

if node.debian? || node.ubuntu?
  # CentOS makes this symlink to the right module dir, and we make assumptions
  # it exists, so be sure to do the same on debian
  link '/etc/apache2/modules' do
    to '/usr/lib/apache2/modules'
  end

  # For reasons I don't understand on Ubuntu, Apache looks for mime.types in
  # /etc/apache2/mime.types even though it's not configured to. So make a
  # symlink
  link '/etc/apache2/mime.types' do
    to '/etc/mime.types'
  end
end

# The package comes pre-installed with module configs, but we dropp off our own
# in fb_modules.conf. Also, we don't want non-Chef controlled module configs.
fb_apache_cleanup_modules 'doit' do
  mod_dir moddir
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

template "#{moddir}/00-mpm.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  # MPM cannot be changed on reload, only restart
  notifies :restart, 'service[apache]'
end

# We want to collect apache stats
template "#{confdir}/status.conf" do
  source 'status.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(:location => '/server-status')
  notifies :restart, 'service[apache]'
end

if node['platform_family'] == 'debian'
  # By default the apache package lays down a '000-default.conf' symlink to
  # sites-available/000-default.conf which contains a generic :80 listener.
  # This can conflict if we want to control :80 ourselves.
  file "#{sitesdir}/000-default.conf" do
    not_if { node['fb_apache']['enable_default_site'] }
    action :delete
  end

  link "#{sitesdir}/000-default.conf" do
    only_if { node['fb_apache']['enable_default_site'] }
    to '../sites-available/000-default.conf'
  end
end

service 'apache' do
  service_name svc
  action [:enable, :start]
end
