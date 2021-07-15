#
# Cookbook:: fb_nginx
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

package 'nginx' do
  only_if { node['fb_nginx']['manage_packages'] }
  action :upgrade
end

sitesdir = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/nginx/conf.d',
  ['debian'] => '/etc/nginx/sites-enabled',
)

moddir = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/nginx/conf.modules.d',
  ['debian'] => '/etc/nginx/modules-enabled',
)

sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/sysconfig/nginx',
  ['debian'] => '/etc/default/nginx',
)

[sitesdir, moddir].uniq.each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

file '/etc/nginx/conf.d/fb_nginx.conf' do
  action :delete
end

template sysconfig do
  owner 'root'
  group 'root'
  mode '0644'
  source 'sysconfig.erb'
  notifies :restart, 'service[nginx]'
end

template '/etc/nginx/nginx.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  variables({ :sitesdir => sitesdir })
  notifies :restart, 'service[nginx]'
end

template "#{moddir}/fb_modules.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nginx]'
end

template "#{sitesdir}/fb_sites.conf" do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nginx]'
end

if node['platform_family'] == 'debian'
  # By default the nginx package lays down a 'default' symlink to
  # sites-available/default which contains a generic :80 listener.
  # This can conflict if we want to control :80 ourselves.
  file "#{sitesdir}/default" do
    not_if { node['fb_nginx']['enable_default_site'] }
    action :delete
  end

  link "#{sitesdir}/default" do
    only_if { node['fb_nginx']['enable_default_site'] }
    to '../sites-available/default'
  end
end

fb_nginx_create_certs 'do it' do
  only_if { node['fb_nginx']['enable'] }
end

service 'nginx' do
  only_if { node['fb_nginx']['enable'] }
  action [:enable, :start]
end

service 'disable nginx' do
  not_if { node['fb_nginx']['enable'] }
  service_name 'nginx'
  action [:stop, :disable]
end
