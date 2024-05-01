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

raise 'foobar'

node.default['fb_apache']['module_packages']['wsgi'] =
  case node['platform_family']
  when 'rhel'
    node['platform_version'].to_f >= 8 ? 'python3-mod_wsgi' : 'mod_wsgi'
  when 'debian'
    'libapache2-mod-wsgi-py3'
  else
    'mod_wsgi'
  end

# Case makes sense in every other case, so lets keep it here for consistency
# rubocop:disable Chef/Style/UnnecessaryPlatformCaseStatement
node.default['fb_apache']['modules_mapping']['wsgi'] =
  case node['platform_family']
  when 'rhel'
    node['platform_version'].to_f >= 8 ? 'mod_wsgi_python3.so' : 'mod_wsgi.so'
  else
    'mod_wsgi.so'
  end
# rubocop:enable Chef/Style/UnnecessaryPlatformCaseStatement

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

httpdir = value_for_platform_family(
  'rhel' => '/etc/httpd',
  'debian' => '/etc/apache2',
)

confdir =
  case node['platform_family']
  when 'rhel'
    "#{httpdir}/conf.d"
  when 'debian'
    case apache_version
    when '2.2'
      "#{httpdir}/conf.d"
    when '2.4'
      "#{httpdir}/conf-enabled"
    end
  end

baseconfig = value_for_platform_family(
 'rhel' => "#{httpdir}/conf/httpd.conf",
 'debian' => "#{httpdir}/apache2.conf",
)

sitesdir = value_for_platform_family(
  'rhel' => confdir,
  'debian' => "#{httpdir}/sites-enabled",
)

moddir =
  case node['platform_family']
  when 'rhel'
    "#{httpdir}/conf.modules.d"
  when 'debian'
    case apache_version
    when '2.2'
      "#{httpdir}/modules-enabled"
    when '2.4'
      "#{httpdir}/mods-enabled"
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

# By default the apache package installs some default config files which we're probably not interested in
if node['platform_family'] == 'rhel'
  %w{autoindex ssl userdir welcome}.each do |file|
    file "#{sitesdir}/#{file}.conf" do
      not_if { node['fb_apache']['enable_default_site'] }
      action :delete
    end
  end
end

# The package comes pre-installed with module configs, but we dropp off our own
# in fb_modules.conf. Also, we don't want non-Chef controlled module configs.
fb_apache_cleanup_modules 'doit' do
  mod_dir moddir
end

template "#{baseconfig}" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :reload, 'service[apache]'
end

template "#{moddir}/fb_modules.conf" do
  not_if { node.centos6? }
  owner 'root'
  group 'root'
  mode '0644'
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :restart, 'service[apache]'
end

template "#{sitesdir}/fb_sites.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :reload, 'service[apache]'
end

template "#{confdir}/fb_apache.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :reload, 'service[apache]'
end

template "#{moddir}/00-mpm.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  # MPM cannot be changed on reload, only restart
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :restart, 'service[apache]'
end

# We want to collect apache stats
template "#{confdir}/status.conf" do
  source 'status.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :verify, 'fb_apache_verify_configs[doit]', :before
  notifies :restart, 'service[apache]'
end

moddirbase = ::File.basename(moddir)
sitesdirbase = ::File.basename(sitesdir)
confdirbase = ::File.basename(confdir)
fb_apache_verify_configs 'doit' do
  httpdir httpdir
  moddir moddirbase
  sitesdir sitesdirbase
  confdir confdirbase
  action :nothing
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

  %w{charset localized-error-pages other-vhosts-access-log security serve-cgi-bin}.each do |file|
    file "#{confdir}/#{file}.conf" do
      action :delete
    end
  end
end

service 'apache' do
  service_name svc
  action [:enable, :start]
end
