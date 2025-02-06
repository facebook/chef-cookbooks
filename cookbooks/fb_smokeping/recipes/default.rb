#
# Cookbook Name:: fb_smokeping
# Recipe:: default
#
# Copyright (c) 2021-present, Vicarious, Inc.
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

packages = value_for_platform(
  ['debian', 'ubuntu'] => { :default => %w{fcgiwrap smokeping} },
)

package packages do
  action :upgrade
end

node.default['fb_apache']['modules'] << 'cgi'

# Set up the smokeping group and user
FB::Users.initialize_group(node, 'smokeping')
node.default['fb_users']['users']['smokeping'] = {
  'gid' => 'smokeping',
  'shell' => '/bin/bash',
  'home' => '/var/lib/smokeping',
  'action' => :add,
}

directory '/var/run/smokeping' do
  mode '0755'
  owner 'smokeping'
  group node.root_group
end

directory '/var/lib/smokeping' do
  mode '0755'
  owner 'smokeping'
  group 'smokeping'
end

# Owned by the apache/nginx user
directory '/var/cache/smokeping/images/' do
  mode '0755'
  owner 'www-data'
  group 'www-data'
end

# secrets need to be readable by smokeping user
template '/etc/smokeping/smokeping_secrets' do
  source 'smokeping_secrets.erb'
  mode '0640'
  owner 'smokeping'
  group 'smokeping'
end

cookbook_file '/etc/smokeping/config' do
  mode '0644'
  owner node.root_user
  group node.root_group
end

directory '/etc/smokeping/config.d' do
  mode '0755'
  owner 'smokeping'
  group 'smokeping'
end

%w{
  Alerts
  General
  Database
  Presentation
  Probes
  Slaves
  Targets
  pathnames
}.each do |config|
  template "/etc/smokeping/config.d/#{config}" do
    source "#{config}.erb"
    mode '0644'
    owner node.root_user
    group node.root_group
    notifies :restart, 'service[smokeping]'
  end
end

link '/var/www/html/smokeping' do
  to '/usr/share/smokeping/www/'
end

link '/usr/share/smokeping/www/smokeping.cgi' do
  to '/usr/lib/cgi-bin/smokeping.cgi'
end

service 'fcgiwrap' do
  action [:enable, :start]
end

service 'smokeping' do
  action [:enable, :start]
end
