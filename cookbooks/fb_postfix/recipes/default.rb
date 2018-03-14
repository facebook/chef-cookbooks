#
# Cookbook Name:: fb_postfix
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2011-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

package 'postfix' do
  action :upgrade
end

template '/etc/postfix/main.cf' do
  source 'main.cf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # We restart here instead of reloading because some main.cf changes require
  # a full restart (e.g. inet_interfaces)
  notifies :restart, 'service[postfix]'
end

%w{
  localdomains
  relaydomains
  mynetworks
}.each do |file|
  template "/etc/postfix/#{file}" do
    source 'line_config.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :reload, 'service[postfix]'
    variables(
      :file => file,
    )
  end
end

# postfix remnant blocks running postalias if it exists
file '/etc/postfix/__db.aliases.db' do
  action :delete
end

template '/etc/postfix/aliases' do
  source 'aliases.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[postalias /etc/postfix/aliases]', :immediately
  notifies :reload, 'service[postfix]'
end

template '/etc/postfix/master.cf' do
  mode '0644'
  owner 'root'
  group 'root'
  source 'master.cf.erb'
  notifies :restart, 'service[postfix]'
end

template '/etc/postfix/custom_headers.regexp' do
  mode '0644'
  owner 'root'
  group 'root'
  source 'custom_headers.regexp.erb'
  notifies :reload, 'service[postfix]'
end

# setup aliases file & db
execute 'postalias /etc/postfix/aliases' do
  action :nothing
end

%w{
  access
  canonical
  etrn_access
  local_access
  sasl_auth
  sasl_passwd
  transport
  virtual
}.each do |text_map_rel|
  text_map = "/etc/postfix/#{text_map_rel}"

  template text_map do
    source 'db_file.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, "execute[postmap #{text_map}]", :immediately
    notifies :reload, 'service[postfix]'
    variables(
      :db_file => text_map_rel,
    )
  end

  execute "postmap #{text_map}" do
    action :nothing
  end
end

service 'postfix' do
  only_if { node['fb_postfix']['enable'] }
  supports :reload => true
  action [:enable, :start]
end

service 'disable postfix' do
  not_if { node['fb_postfix']['enable'] }
  service_name 'postfix'
  action [:stop, :disable]
end
