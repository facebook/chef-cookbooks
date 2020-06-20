#
# Cookbook Name:: fb_postfix
# Recipe:: default
#
# Copyright (c) 2011-present, Facebook, Inc.
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

include_recipe 'fb_postfix::packages'

# if someone is using fb_syslog
if node['fb_syslog']
  # If we append but it's not an array, things go boom, so make sure it's
  # an array
  unless node['fb_syslog']['rsyslog_additional_sockets']
    node.default['fb_syslog']['rsyslog_additional_sockets'] = []
  end
  node.default['fb_syslog']['rsyslog_additional_sockets'] <<
    '/var/spool/postfix/dev/log'
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
    if text_map_rel == 'sasl_passwd'
      mode '0600'
      sensitive true
    else
      mode '0644'
    end
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

if Chef::VERSION.to_i >= 16
  notify_group 'masking postfix' do
    only_if do
      !node['fb_postfix']['enable'] && node['fb_postfix']['mask_service']
    end
    action :run
    notifies :mask, 'service[disable postfix]'
  end
else
  # rubocop:disable Lint/UnneededCopDisableDirective
  # rubocop:disable ChefDeprecations/LogResourceNotifications
  log 'masking postfix' do
    only_if do
      !node['fb_postfix']['enable'] && node['fb_postfix']['mask_service']
    end
    notifies :mask, 'service[disable postfix]'
  end
  # rubocop:enable ChefDeprecations/LogResourceNotifications
  # rubocop:enable Lint/UnneededCopDisableDirective
end
