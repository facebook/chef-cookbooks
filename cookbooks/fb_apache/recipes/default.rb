#
# Cookbook Name:: fb_apache
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

confdir = value_for_platform(
  'redhat' => { :default => '/etc/httpd/conf.d' },
  ['debian', 'ubuntu'] => { :default => '/etc/apache2/sites-enabled' },
)

pkgs = value_for_platform(
  'redhat' => { :default => ['httpd', 'mod_ssl'] },
  ['debian', 'ubuntu'] => { :default => ['apache2'] },
)

svc = value_for_platform(
  'redhat' => { :default => 'httpd' },
  ['debian', 'ubuntu'] => { :default => 'apache2' },
)

package pkgs do
  only_if { node['fb_apache']['manage_packages'] }
  action :upgrade
end

template "#{confdir}/fb_apache_sites.cfg" do
  source 'site.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

service svc do
  action [:enable, :start]
end
